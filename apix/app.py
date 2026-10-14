#!/usr/bin/env python3
"""
APIX v2 — API Gateway Marzban + SSH Management
- Reverse proxy default -> panel Marzban (dashboard/sub/api bawaan)
- /apix/*  : gateway JSON (auth X-API-Key)
- Endpoint SSH lengkap: create/list/renew/delete/lock/unlock (dropbear via useradd)
"""
import hashlib, json, os, re, secrets, sqlite3, subprocess, threading, time, urllib.request, urllib.error, pwd
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware

BASE = Path("/var/lib/marzban/apix")
DB_PATH = BASE / "keys.db"
MZB_BASE = "http://127.0.0.1:8000"
KEY_PREFIX = "apx_"
LIMIT_DB = Path("/var/lib/marzban-cli/ssh-limit.db")
BASE.mkdir(parents=True, exist_ok=True)
LIMIT_DB.parent.mkdir(parents=True, exist_ok=True)
_db_lock = threading.Lock()
DOMAIN = os.environ.get("APIX_DOMAIN", "scbagus.nexusdev.my.id")

def db():
    c = sqlite3.connect(DB_PATH)
    c.execute("""CREATE TABLE IF NOT EXISTS keys(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        key_hash TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER,
        enabled INTEGER DEFAULT 1,
        last_used_at INTEGER,
        calls INTEGER DEFAULT 0)""")
    return c

def now(): return int(time.time())
def key_hash(k): return hashlib.sha256(k.encode()).hexdigest()

# ================= Marzban client =================
_tk_lock = threading.Lock()
_token = {"v": None, "t": 0}

def mzb_token():
    with _tk_lock:
        if _token["v"] and now() - _token["t"] < 1800:
            return _token["v"]
        data = urllib.parse.urlencode({"username": os.environ["MZB_ADMIN_USER"],
                                       "password": os.environ["MZB_ADMIN_PASS"]}).encode()
        req = urllib.request.Request(MZB_BASE + "/api/admin/token", data=data,
                                     headers={"Content-Type": "application/x-www-form-urlencoded"})
        with urllib.request.urlopen(req, timeout=15) as r:
            tok = json.load(r)["access_token"]
        _token["v"], _token["t"] = tok, now()
        return tok

def mzb(method, path, body=None, token=None, retry=True):
    tok = token or mzb_token()
    req = urllib.request.Request(MZB_BASE + path, method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if e.code == 401 and retry and not token:
            with _tk_lock: _token["v"] = None
            return mzb(method, path, body, retry=False)
        try: detail = json.loads(e.read())
        except Exception: detail = {"detail": str(e)}
        return JSONResponse(status_code=e.code, content=detail)
    except urllib.error.URLError as e:
        return JSONResponse(status_code=502, content={"detail": f"marzban unreachable: {e}"})

def require_admin(request: Request):
    auth = request.headers.get("authorization") or ""
    tok = auth[7:].strip() if auth.lower().startswith("bearer ") else ""
    if not tok:
        raise HTTPException(401, "Token admin tidak ada — login di /dashboard dulu")
    r = mzb("GET", "/api/admin", token=tok, retry=False)
    if not isinstance(r, dict):
        raise HTTPException(401, "Token admin tidak valid/expired — refresh dashboard")
    return tok

def check_apikey(request: Request):
    key = request.headers.get("x-api-key") or ""
    auth = request.headers.get("authorization") or ""
    if auth.lower().startswith("bearer ") and not key:
        key = auth[7:].strip()
    if not key:
        raise HTTPException(401, "Kirim header X-API-Key: apx_...")
    with _db_lock:
        c = db()
        rows = c.execute("SELECT * FROM keys WHERE enabled=1").fetchall()
        c.close()
    matched = None
    for row in rows:
        try:
            if decrypt_key(row[2]) == key:
                matched = row; break
        except Exception:
            continue
    if not matched:
        # fallback: key lama masih disimpan sbg hash
        c = db()
        matched = c.execute("SELECT * FROM keys WHERE key_hash=?", (key_hash(key),)).fetchone()
        c.close()
    if not matched:
        raise HTTPException(401, "API key tidak valid")
    _id, _n, _h, _c, expires_at, enabled, _lu, _calls = matched
    if not enabled: raise HTTPException(403, "API key dinonaktifkan")
    if expires_at and now() > expires_at: raise HTTPException(403, "API key kedaluwarsa")
    with _db_lock:
        c = db()
        c.execute("UPDATE keys SET last_used_at=?, calls=calls+1 WHERE id=?", (now(), _id))
        c.commit(); c.close()

# ================= SSH engine =================
def ssh_users():
    out = subprocess.run(["awk", "-F:", '$3>=1000 && $3<65534 && $7=="/bin/false"{print $1}', "/etc/passwd"],
                         capture_output=True, text=True)
    return sorted(out.stdout.split())

def ssh_exp_day(u):
    out = subprocess.run(["getent", "shadow", u], capture_output=True, text=True).stdout
    f = out.split(":")[7] if ":" in out else ""
    return int(f) if f.isdigit() else 0

def ssh_today(): return now() // 86400

def ssh_status(u):
    e = ssh_exp_day(u)
    if e > 0 and ssh_today() >= e: return "expired"
    st = subprocess.run(["passwd", "-S", u], capture_output=True, text=True).stdout.split()
    return "locked" if len(st) > 1 and st[1] == "L" else "active"

def ssh_limit_get(u):
    if not LIMIT_DB.exists(): return 0
    for line in LIMIT_DB.read_text().splitlines():
        if line.startswith(u + "|"):
            try: return int(line.split("|")[1])
            except ValueError: return 0
    return 0

def ssh_limit_set(u, lim):
    lines = []
    if LIMIT_DB.exists():
        lines = [l for l in LIMIT_DB.read_text().splitlines() if not l.startswith(u + "|")]
    if isinstance(lim, int) and lim > 0:
        lines.append(f"{u}|{lim}")
    LIMIT_DB.write_text("\n".join(lines) + ("\n" if lines else ""))
    LIMIT_DB.chmod(0o600)

def ssh_account_dict(u):
    e = ssh_exp_day(u)
    return {"username": u, "status": ssh_status(u),
            "expires_at": e * 86400 if e else None,
            "expires": datetime.fromtimestamp(e * 86400, tz=timezone.utc).strftime("%Y-%m-%d") if e else "unlimited",
            "limit_login": ssh_limit_get(u),
            "connect": {"host": DOMAIN, "port": 443, "path": "/ssh-ws", "mode": "WS+TLS (HTTP Custom/[] apps)"}}

def ssh_create(u, p, days, lim):
    if not re.match(r"^[a-z_][a-z0-9_-]{2,31}$", u):
        return None, "Username tidak valid: 3-32 char, huruf kecil/angka/-/_ (awal huruf)"
    if subprocess.run(["id", u], capture_output=True).returncode == 0:
        return None, f"Username '{u}' sudah dipakai"
    if not p: p = secrets.token_urlsafe(9)[:10]
    shells = Path("/etc/shells")
    if shells.exists() and "/bin/false" not in shells.read_text():
        with open(shells, "a") as f: f.write("/bin/false\n")
    r = subprocess.run(["useradd", "-M", "-s", "/bin/false", u], capture_output=True, text=True)
    if r.returncode != 0:
        return None, "useradd gagal: " + r.stderr.strip()
    subprocess.run(["chpasswd"], input=f"{u}:{p}\n", capture_output=True, text=True)
    exp_day = ssh_today() + int(days)
    subprocess.run(["chage", "-E", str(exp_day), u], capture_output=True)
    ssh_limit_set(u, int(lim or 0))
    acc = ssh_account_dict(u)
    acc["password"] = p
    return acc, None

# ================= app =================
app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"],
                   allow_headers=["X-API-Key", "Content-Type", "Authorization"])

@app.middleware("http")
async def gateway(request: Request, call_next):
    path = request.url.path
    if path == "/apix" or path.startswith("/apix/"):
        return await call_next(request)
    url = MZB_BASE + path + ("?" + request.url.query if request.url.query else "")
    body = await request.body()
    headers = {k: v for k, v in request.headers.items()
               if k.lower() not in ("host", "content-length", "connection", "accept-encoding")}
    headers["Accept-Encoding"] = "identity"
    req = urllib.request.Request(url, data=body if body else None, method=request.method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            rbody = r.read()
            resp = Response(content=rbody, status_code=r.status,
                            media_type=r.headers.get("Content-Type", "application/octet-stream"))
            for h in ("location", "set-cookie"):
                if r.headers.get(h): resp.headers[h] = r.headers.get(h)
            return resp
    except urllib.error.HTTPError as e:
        return Response(content=e.read(), status_code=e.code,
                        media_type=e.headers.get("Content-Type", "application/json"))
    except Exception as e:
        return JSONResponse(status_code=502, content={"detail": str(e)})

# ================= APIX routes =================
@app.get("/apix")
async def apix_home():
    return JSONResponse({"service": "APIX v2", "docs": "/apix/docs",
                         "manage": "/dashboard → tombol API Keys"})

@app.get("/apix/docs")
async def apix_docs():
    return JSONResponse({
        "service": "APIX Gateway v2",
        "auth": 'header "X-API-Key: apx_..."',
        "proxy_endpoints": {
          "GET  /apix/system": "stats",
          "GET  /apix/users": "list user proxy",
          "POST /apix/users": "create user proxy — {username, expire(unix|0), data_limit, proxies:{vmess:{},vless:{},trojan:{},shadowsocks:{}}}",
          "GET  /apix/user?username=": "detail",
          "PUT  /apix/user": "edit — body + username",
          "DELETE /apix/user?username=": "hapus",
          "POST /apix/user/reset": "reset quota — {username}",
        },
        "ssh_endpoints": {
          "GET  /apix/ssh": "list akun SSH",
          "POST /apix/ssh": "create — {username, password?(kosong=acak), days, limit_login?(0=unlimited)}",
          "PUT  /apix/ssh": "renew — {username, days}",
          "DELETE /apix/ssh?username=": "hapus",
          "POST /apix/ssh/lock": "{username}",
          "POST /apix/ssh/unlock": "{username}",
        }})

# ---- proxy (API key) ----
@app.get("/apix/system")
async def f_system(request: Request):
    check_apikey(request); return mzb("GET", "/api/system")

@app.get("/apix/users")
async def f_users(request: Request):
    check_apikey(request)
    q = str(request.url.query)
    return mzb("GET", "/api/users" + ("?" + q if q else ""))

ALL_INBOUNDS = {
    "vmess": ["VMess WS 443", "VMess WS 80", "VMess HU 443", "VMess HU 80"],
    "vless": ["VLESS TCP TLS 443", "VLESS WS 443", "VLESS TCP 80", "VLESS WS 80",
              "VLESS HU 443", "VLESS HU 80"],
    "trojan": ["Trojan WS 443", "Trojan WS 80", "Trojan HU 443", "Trojan HU 80"],
    "shadowsocks": ["Shadowsocks WS 443", "Shadowsocks WS 80",
                    "Shadowsocks HU 443", "Shadowsocks HU 80"],
}

@app.post("/apix/users")
async def f_users_create(request: Request):
    check_apikey(request)
    b = await request.json()
    # auto-assign semua inbound sesuai protokol yang diminta (biar links & sub langsung lengkap)
    if not b.get("inbounds"):
        proxies = b.get("proxies") or {}
        b["inbounds"] = {p: ALL_INBOUNDS.get(p, []) for p in proxies}
    return mzb("POST", "/api/user", b)

def _limit_ip_body(limit_ip):
    """limit_ip -> body extension atas ip limit Marzban (via note + per-proxy config).
    Marzban core belum punya native ip-limit; implement via cron iplimit mzb-tools (limit per username)."""
    try:
        n = int(limit_ip)
        return n if n > 0 else None
    except (TypeError, ValueError):
        return None

def _apply_ip_limit(username, limit_ip):
    n = _limit_ip_body(limit_ip)
    if not n: return
    ldb = Path("/var/lib/marzban-cli/ssh-limit.db")  # pakai db limit yang sama (mzb-tools iplimit cron baca ini)
    ldb.parent.mkdir(parents=True, exist_ok=True)
    lines = [l for l in ldb.read_text().splitlines() if not l.startswith(username + "|")] if ldb.exists() else []
    lines.append(f"{username}|{n}")
    ldb.write_text("\n".join(lines) + "\n")
    ldb.chmod(0o600)

# ================= SIMPLE ENDPOINTS: /createX, /delX, dst =================
SIMPLE_PROTOS = ["vmess", "vless", "trojan", "shadowsocks"]

def _simple_create(proto: str, username: str, quota_gb: float | None, days: int | None, limit_ip: int | None = None):
    """bikin user 1 protokol; respon ringkas: sub url"""
    if not username:
        return JSONResponse(status_code=422, content={"success": False, "error": "username wajib"})
    body: dict = {
        "username": username,
        "expire": (int(time.time()) + int(days) * 86400) if days else 0,
        "data_limit": int(quota_gb * 1024**3) if quota_gb else 0,
        "proxies": {proto: {}},
        "inbounds": {proto: ALL_INBOUNDS[proto]},
    }
    r = mzb("POST", "/api/user", body)
    if isinstance(r, JSONResponse):
        raw = json.loads(bytes(r.body)) if hasattr(r, "body") else {}
        err = raw.get("detail", "gagal")
        # pesan lebih enak dibaca
        if "already exists" in str(err):
            err = f"username '{username}' sudah dipakai"
        elif isinstance(err, dict) and "username" in err:
            err = str(err["username"]).replace("Value error, ", "")
        return JSONResponse(status_code=400, content={"success": False, "error": err})
    if limit_ip:
        _apply_ip_limit(username, limit_ip)
    return {
        "success": True,
        "username": username,
        "protocol": proto,
        "quota": f"{quota_gb} GB" if quota_gb else "unlimited",
        "expired": f"{days} hari" if days else "unlimited",
        "limit_ip": f"{limit_ip} IP" if limit_ip else "unlimited",
        "subscription_url": r.get("subscription_url", ""),
    }

def _simple_delete_user(username: str):
    if not username:
        return JSONResponse(status_code=422, content={"success": False, "error": "username wajib"})
    r = mzb("DELETE", f"/api/user/{username}")
    if isinstance(r, JSONResponse):
        return JSONResponse(status_code=404, content={"success": False, "error": f"user '{username}' tidak ada"})
    # hapus juga ip-limit record
    _apply_ip_limit(username, 0)
    return {"success": True, "detail": f"{username} dihapus"}

def _simple_get_user(username: str):
    if not username:
        return JSONResponse(status_code=422, content={"success": False, "error": "username wajib"})
    r = mzb("GET", f"/api/user/{username}")
    if isinstance(r, JSONResponse):
        return JSONResponse(status_code=404, content={"success": False, "error": f"user '{username}' tidak ada"})
    used = r.get("used_traffic", 0); lim = r.get("data_limit")
    exp = r.get("expire")
    import datetime as _dt
    return {
        "success": True,
        "username": r.get("username"),
        "status": r.get("status"),
        "used": f"{used/1024**3:.2f} GB" if used else "0 B",
        "quota": f"{lim/1024**3:.0f} GB" if lim else "unlimited",
        "expired": _dt.datetime.utcfromtimestamp(exp).strftime("%Y-%m-%d") if exp else "unlimited",
        "subscription_url": r.get("subscription_url", ""),
    }

def _simple_renew(username: str, days: int, quota_gb: float | None):
    r = mzb("GET", f"/api/user/{username}")
    if isinstance(r, JSONResponse):
        return JSONResponse(status_code=404, content={"success": False, "error": f"user '{username}' tidak ada"})
    now_ts = int(time.time())
    base = r.get("expire") or 0
    new_exp = max(base, now_ts) + days * 86400 if days else 0
    body = {"expire": new_exp}
    if quota_gb is not None:
        body["data_limit"] = int(quota_gb * 1024**3)
    mzb("PUT", f"/api/user/{username}", body)
    return {"success": True, "username": username,
            "expired_baru": _simple_get_user(username)["expired"],
            "quota_baru": _simple_get_user(username)["quota"]}

for _proto in SIMPLE_PROTOS:
    def _make(p):
        async def create(request: Request):
            check_apikey(request)
            b = await request.json()
            return _simple_create(p, (b.get("username") or "").strip(),
                                  b.get("quota_gb"), b.get("days"), b.get("limit_ip"))
        async def delete(request: Request):
            check_apikey(request)
            u = request.query_params.get("username")
            return _simple_delete_user(u)
        async def getONE(request: Request):
            check_apikey(request)
            return _simple_get_user(request.query_params.get("username"))
        async def renew(request: Request):
            check_apikey(request)
            b = await request.json()
            return _simple_renew((b.get("username") or "").strip(),
                                 int(b.get("days") or 0), b.get("quota_gb"))
        return create, delete, getONE, renew
    _c, _d, _g, _r = _make(_proto)
    app.post(f"/apix/create{_proto}")(_c)
    app.delete(f"/apix/del{_proto}")(_d)
    app.get(f"/apix/get{_proto}")(_g)
    app.post(f"/apix/renew{_proto}")(_r)


@app.get("/apix/user")
async def f_user_get(request: Request):
    check_apikey(request)
    u = request.query_params.get("username")
    if not u: raise HTTPException(422, "param username wajib")
    return mzb("GET", f"/api/user/{u}")

@app.put("/apix/user")
async def f_user_put(request: Request):
    check_apikey(request)
    b = await request.json()
    u = b.pop("username", None) or request.query_params.get("username")
    if not u: raise HTTPException(422, "username wajib")
    return mzb("PUT", f"/api/user/{u}", b)

@app.delete("/apix/user")
async def f_user_del(request: Request):
    check_apikey(request)
    u = request.query_params.get("username")
    if not u: raise HTTPException(422, "param username wajib")
    return mzb("DELETE", f"/api/user/{u}")

@app.post("/apix/user/reset")
async def f_user_reset(request: Request):
    check_apikey(request)
    b = await request.json()
    if not b.get("username"): raise HTTPException(422, "username wajib di body")
    return mzb("POST", f"/api/user/{b['username']}/reset")

# ---- SSH (API key) ----
@app.get("/apix/ssh")
async def ssh_list(request: Request):
    check_apikey(request)
    return {"ssh": [ssh_account_dict(u) for u in ssh_users()]}

@app.post("/apix/ssh")
async def ssh_add(request: Request):
    check_apikey(request)
    b = await request.json()
    acc, err = ssh_create((b.get("username") or "").strip(), b.get("password") or "",
                          int(b.get("days") or 30), int(b.get("limit_login") or 0))
    if err: return JSONResponse(status_code=400, content={"success": False, "error": err})
    return {"success": True, "account": acc}

@app.put("/apix/ssh")
async def ssh_renew(request: Request):
    check_apikey(request)
    b = await request.json()
    u, days = b.get("username"), int(b.get("days") or 0)
    if not u: raise HTTPException(422, "username wajib")
    if subprocess.run(["id", u], capture_output=True).returncode != 0:
        return JSONResponse(status_code=404, content={"success": False, "error": f"user '{u}' tidak ada"})
    exp_day = ssh_today() + days
    subprocess.run(["chage", "-E", str(exp_day), u], capture_output=True)
    subprocess.run(["passwd", "-u", u], capture_output=True)
    return {"success": True, "username": u, "account": ssh_account_dict(u)}

@app.delete("/apix/ssh")
async def ssh_del(request: Request):
    check_apikey(request)
    u = request.query_params.get("username")
    if not u: raise HTTPException(422, "param username wajib")
    r = subprocess.run(["userdel", "-f", u], capture_output=True, text=True)
    if r.returncode != 0:
        return JSONResponse(status_code=400, content={"success": False, "error": r.stderr.strip() or "gagal hapus"})
    ssh_limit_set(u, 0)
    return {"success": True, "detail": f"{u} dihapus"}

@app.post("/apix/ssh/lock")
async def ssh_lock(request: Request):
    check_apikey(request)
    u = (await request.json()).get("username")
    if not u: raise HTTPException(422, "username wajib")
    subprocess.run(["passwd", "-l", u], capture_output=True)
    return {"success": True, "username": u, "status": ssh_status(u)}

@app.post("/apix/ssh/unlock")
async def ssh_unlock(request: Request):
    check_apikey(request)
    u = (await request.json()).get("username")
    if not u: raise HTTPException(422, "username wajib")
    subprocess.run(["passwd", "-u", u], capture_output=True)
    return {"success": True, "username": u, "status": ssh_status(u)}

# ---- kelola API keys ----
import base64 as _b64
SECRET_X = hashlib.sha256((os.environ.get("MZB_ADMIN_PASS", "apix") + "apix-salt").encode()).digest()

def encrypt_key(plain: str) -> str:
    x = bytes(b ^ SECRET_X[i % len(SECRET_X)] for i, b in enumerate(plain.encode()))
    return _b64.b64encode(x).decode()

def decrypt_key(enc: str) -> str:
    x = _b64.b64decode(enc)
    return bytes(b ^ SECRET_X[i % len(SECRET_X)] for i, b in enumerate(x)).decode()

def mask(kh): return kh[:8] + "…" + kh[-6:]

@app.get("/apix/keys")
async def keys_list(request: Request):
    require_admin(request)
    c = db()
    rows = c.execute("SELECT id,name,key_hash,created_at,expires_at,enabled,last_used_at,calls FROM keys ORDER BY id").fetchall()
    c.close()
    out = []
    for r in rows:
        try: full = decrypt_key(r[2])
        except Exception: full = None
        out.append({"id": r[0], "name": r[1], "key": mask(r[2]), "full_key": full,
                    "created_at": r[3], "expires_at": r[4], "enabled": bool(r[5]),
                    "last_used_at": r[6], "calls": r[7],
                    "expired": bool(r[4] and now() > r[4])})
    return {"keys": out}

@app.post("/apix/keys")
async def keys_create(request: Request):
    require_admin(request)
    b = await request.json()
    name = (b.get("name") or "key").strip()[:60]
    exp = b.get("expires_at")
    exp = None if not exp else int(exp)
    key = KEY_PREFIX + secrets.token_hex(20)
    with _db_lock:
        c = db()
        c.execute("INSERT INTO keys(name,key_hash,created_at,expires_at) VALUES(?,?,?,?)",
                  (name, encrypt_key(key), now(), exp))
        c.commit(); c.close()
    return {"ok": True, "name": name, "key": key, "expires_at": exp,
            "expires": datetime.fromtimestamp(exp, tz=timezone.utc).strftime("%Y-%m-%d %H:%M UTC") if exp else "unlimited",
            "note": "Key bisa disalin kapan saja dari daftar"}

@app.post("/apix/keys/rotate")
async def keys_rotate(request: Request):
    require_admin(request)
    kid = int((await request.json()).get("id", 0))
    key = KEY_PREFIX + secrets.token_hex(20)
    with _db_lock:
        c = db()
        if not c.execute("SELECT id FROM keys WHERE id=?", (kid,)).fetchone():
            c.close(); raise HTTPException(404, "Key tidak ada")
        c.execute("UPDATE keys SET key_hash=?, calls=0 WHERE id=?", (encrypt_key(key), kid))
        c.commit(); c.close()
    return {"ok": True, "key": key, "note": "Key lama MATI — simpan key baru"}

@app.post("/apix/keys/toggle")
async def keys_toggle(request: Request):
    require_admin(request)
    kid = int((await request.json()).get("id", 0))
    with _db_lock:
        c = db()
        row = c.execute("SELECT enabled FROM keys WHERE id=?", (kid,)).fetchone()
        if not row: c.close(); raise HTTPException(404, "Key tidak ada")
        c.execute("UPDATE keys SET enabled=? WHERE id=?", (0 if row[0] else 1, kid))
        c.commit(); c.close()
        return {"ok": True, "enabled": not bool(row[0])}

@app.delete("/apix/keys")
async def keys_del(request: Request):
    require_admin(request)
    kid = int(request.query_params.get("id", 0))
    with _db_lock:
        c = db(); n = c.execute("DELETE FROM keys WHERE id=?", (kid,)).rowcount
        c.commit(); c.close()
    if not n: raise HTTPException(404, "Key tidak ada")
    return {"ok": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8901, log_level="warning")
