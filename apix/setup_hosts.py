#!/usr/bin/env python3
"""Setup hosts Marzban untuk skema SC Nexus:
- address/host/sni = DOMAIN (dari XRAY_SUBSCRIPTION_URL_PREFIX di .env)
- security TLS di 443, none di 80
- path sesuai xray config (/proto-ws, /proto-hu)
- remark: 🌀 Nexus ({USERNAME}) [{PROTO} {TRANSPORT} {TLS|NoTLS}]
- alpn/fingerprint: 'none' (enum valid)
Idempotent: safe dijalankan berulang."""
import json, os, re, sqlite3

# domain dari env container (XRAY_SUBSCRIPTION_URL_PREFIX di-inject marzban) atau argumen
dom = os.environ.get("XRAY_SUBSCRIPTION_URL_PREFIX", "").replace("https://", "").replace("http://", "")
if not dom:
    raise SystemExit("DOMAIN tidak ditemukan (env XRAY_SUBSCRIPTION_URL_PREFIX)")

c = sqlite3.connect("/var/lib/marzban/db.sqlite3")
proto_map = {"VLESS":"vless","VMess":"vmess","Trojan":"trojan","Shadowsocks":"shadowsocks"}

def path_for(tag):
    T = tag.split(" ")[0]
    proto = proto_map.get(T, T.lower())
    if " WS " in tag:  return f"/{proto}-ws"
    if " HU " in tag:  return f"/{proto}-hu"
    if " XHTTP " in tag: return f"/{proto}-xh"
    return None  # TCP

have = {r[0] for r in c.execute("SELECT inbound_tag FROM hosts").fetchall()}

# update yang ada
for hid, tag in c.execute("SELECT id, inbound_tag FROM hosts").fetchall():
    sec = "tls" if "443" in tag else "none"
    port = 443 if "443" in tag else 80
    sni = dom if sec == "tls" else ""
    path = path_for(tag) or ""
    T = tag.split(" ")[0]
    transport = {"WS": "WS", "HU": "HTTPUp", "TCP": "TCP"}.get(re.search(r"(WS|HU|TCP|XHTTP)", tag).group(1), "")
    remark = f"🌀 Nexus ({{USERNAME}}) [{T} {transport} {sec.upper()}]"
    c.execute("""UPDATE hosts SET address=?, host=?, sni=?, security=?, path=?, port=?, alpn='none',
                 fingerprint='none', remark=? WHERE id=?""",
              (dom, dom, sni, sec, path if path else "inbound_default", port, remark, hid))

# tambah yang hilang (dari inbounds yang belum punya host)
for (tag,) in c.execute("SELECT tag FROM inbounds").fetchall():
    if tag in have: continue
    sec = "tls" if "443" in tag else "none"
    port = 443 if "443" in tag else (80 if "80" in tag else None)
    if port is None: continue
    T = tag.split(" ")[0]
    proto = proto_map.get(T, T.lower())
    m = re.search(r"(WS|HU|TCP|XHTTP)", tag)
    transport = {"WS":"WS","HU":"HTTPUp","TCP":"TCP","XHTTP":"XHTTP"}.get(m.group(1)) if m else ""
    path = path_for(tag) or ""
    remark = f"🌀 Nexus ({{USERNAME}}) [{T} {transport} {sec.upper()}]"
    c.execute("""INSERT INTO hosts(inbound_tag,remark,address,port,sni,host,security,alpn,fingerprint,allowinsecure,is_disabled,path,mux_enable,fragment_setting,random_user_agent,noise_setting,use_sni_as_host)
        VALUES(?,?,?,?,?,?,?,'none','none',0,0,?,0,'',0,'',0)""",
        (tag, remark, dom, port, sni, dom, sec, path if path else "inbound_default"))
c.commit()

print(f"hosts selesai (domain {dom}):")
for r in c.execute("SELECT id,inbound_tag,address,port,path,security,remark FROM hosts ORDER BY id"):
    print(r)
