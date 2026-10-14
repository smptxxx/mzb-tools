/* APIX v3 — tampilan mengikuti design system Marzban (Chakra UI), light/dark otomatis */
(function () {
  if (window.__apixLoaded) return; window.__apixLoaded = true;

  const CSS = `
  /* palet mengikuti theme dashboard */
  #apixOv{--ax-surface:#ffffff;--ax-card:#f7fafc;--ax-text:#1a202c;--ax-muted:#718096;
    --ax-border:#e2e8f0;--ax-inputbg:#ffffff;--ax-hover:#edf2f7;--ax-primary:#3182ce;--ax-primaryh:#2b6cb0;
    --ax-onpri:#ffffff;--ax-red:#e53e3e;--ax-redh:#c53030;
    --ax-okbg:#c6f6d5;--ax-oktx:#22543d;--ax-offbg:#e2e8f0;--ax-offtx:#4a5568;--ax-wrbg:#feebc8;--ax-wrtx:#7b341e;
    --ax-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -2px rgba(0,0,0,.05)}
  #apixOv.axDark{--ax-surface:#2d3748;--ax-card:#1a202c;--ax-text:#e2e8f0;--ax-muted:#a0aec0;
    --ax-border:#4a5568;--ax-inputbg:#1a202c;--ax-hover:#4a5568;--ax-primary:#3182ce;--ax-primaryh:#2b6cb0;
    --ax-onpri:#ffffff;--ax-red:#e53e3e;--ax-redh:#c53030;
    --ax-okbg:rgba(72,187,120,.16);--ax-oktx:#68d391;--ax-offbg:rgba(160,174,192,.16);--ax-offtx:#a0aec0;--ax-wrbg:rgba(237,137,54,.16);--ax-wrtx:#f6ad55;
    --ax-shadow:0 20px 25px -5px rgba(0,0,0,.3),0 10px 10px -5px rgba(0,0,0,.2)}
  #apixBtn{display:inline-flex;align-items:center;justify-content:center;height:32px;padding:0 12px;
    border:1px solid var(--ax-border,#e2e8f0);border-radius:6px;background:transparent;color:inherit;
    font:500 13px/1 system-ui;cursor:pointer;gap:6px;transition:all .15s}
  #apixBtn:hover{background:var(--ax-hover,#edf2f7)}
  #apixOv{position:fixed;inset:0;z-index:1400;background:rgba(0,0,0,.55);display:none;
    align-items:flex-start;justify-content:center;padding:9vh 14px;font:14px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
  #apixWrap{width:100%;max-width:640px;max-height:84vh;overflow:auto;border-radius:6px;
    background:var(--ax-surface);color:var(--ax-text);box-shadow:var(--ax-shadow)}
  .axH{display:flex;align-items:center;justify-content:space-between;padding:16px 20px;border-bottom:1px solid var(--ax-border)}
  .axH h2{margin:0;font-size:16px;font-weight:600;letter-spacing:-.01em}
  .axX{background:transparent;border:0;color:var(--ax-muted);cursor:pointer;font-size:16px;width:28px;height:28px;border-radius:6px;display:flex;align-items:center;justify-content:center}
  .axX:hover{background:var(--ax-hover);color:var(--ax-text)}
  .axBody{padding:20px}
  .axLbl{font-size:12px;font-weight:600;color:var(--ax-muted);margin:0 0 6px}
  .axIn{width:100%;box-sizing:border-box;background:var(--ax-inputbg);border:1px solid var(--ax-border);
    color:var(--ax-text);border-radius:6px;padding:0 12px;height:38px;font:14px system-ui;outline:none;transition:border .15s,box-shadow .15s}
  .axIn:focus{border-color:var(--ax-primary);box-shadow:0 0 0 1px var(--ax-primary)}
  .axIn::placeholder{color:var(--ax-muted)}
  .axPri{display:inline-flex;align-items:center;justify-content:center;height:38px;padding:0 16px;
    background:var(--ax-primary);color:var(--ax-onpri);border:0;border-radius:6px;font:600 14px system-ui;cursor:pointer;transition:background .15s}
  .axPri:hover{background:var(--ax-primaryh)}
  .axPri:disabled{opacity:.6;cursor:default}
  .axSec{display:inline-flex;align-items:center;justify-content:center;height:28px;padding:0 10px;
    background:var(--ax-card);border:1px solid var(--ax-border);color:var(--ax-text);border-radius:6px;font:500 12.5px system-ui;cursor:pointer;transition:background .15s}
  .axSec:hover{background:var(--ax-hover)}
  .axSec.red{color:var(--ax-red);border-color:var(--ax-red)}
  .axSec.red:hover{background:var(--ax-red);color:#fff}
  .axChip{display:inline-flex;align-items:center;justify-content:center;min-width:44px;height:38px;padding:0 10px;
    background:var(--ax-card);border:1px solid var(--ax-border);color:var(--ax-muted);border-radius:6px;font:600 13px system-ui;cursor:pointer;transition:all .15s}
  .axChip:hover,.axChip.on{border-color:var(--ax-primary);color:var(--ax-primary)}
  .axRow{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
  .axKey{font:12.5px ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--ax-card);
    border:1px solid var(--ax-border);border-radius:6px;padding:10px 12px;word-break:break-all;color:var(--ax-primary);display:none;margin-top:10px}
  .axT{width:100%;border-collapse:collapse;font-size:13px;margin-top:4px}
  .axT th{text-align:left;color:var(--ax-muted);font-size:11px;font-weight:700;text-transform:uppercase;
    letter-spacing:.03em;padding:10px 8px;border-bottom:1px solid var(--ax-border)}
  .axT td{padding:12px 8px;border-bottom:1px solid var(--ax-border);vertical-align:middle}
  .axT tr:last-child td{border-bottom:0}
  .axT tr:hover td{background:var(--ax-card)}
  .axPill{display:inline-flex;align-items:center;font-size:11px;font-weight:600;padding:3px 10px;border-radius:999px}
  .axPill.on{background:var(--ax-okbg);color:var(--ax-oktx)}
  .axPill.off{background:var(--ax-offbg);color:ax-offtx;color:var(--ax-offtx)}
  .axPill.wr{background:var(--ax-wrbg);color:var(--ax-wrtx)}
  .axMut{color:var(--ax-muted)}
  .axMono{font-family:ui-monospace,Menlo,monospace;font-size:12px}
  .axAct{display:flex;gap:6px;justify-content:flex-end}
  .axEmpty{text-align:center;color:var(--ax-muted);padding:26px 0;font-size:13px}
  .axNote{font-size:12px;color:var(--ax-muted);margin-top:10px}
  .axCop{color:var(--ax-oktx);background:var(--ax-okbg);font-size:12px;font-weight:600;border-radius:6px;
    padding:6px 10px;display:none;margin-top:8px;width:fit-content}
  .axCode{font:12px ui-monospace,Menlo,monospace;background:var(--ax-card);border:1px solid var(--ax-border);
    border-radius:6px;padding:12px;overflow-x:auto;white-space:pre;color:var(--ax-text);margin:8px 0 4px}
  .axTab{flex:1;text-align:center;background:transparent;border:0;color:var(--ax-muted);font:600 13.5px system-ui;
    padding:13px 10px;cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-1px}
  .axTab.on{color:var(--ax-primary);border-bottom-color:var(--ax-primary)}
  .axTabs{display:flex;padding:0 20px;border-bottom:1px solid var(--ax-border)}
  `; const st = document.createElement("style"); st.textContent = CSS; document.head.appendChild(st);

  const btn = document.createElement("button"); btn.id = "apixBtn"; btn.textContent = "🔑 API Keys";

  const ov = document.createElement("div"); ov.id = "apixOv";
  ov.innerHTML = `
  <div id="apixWrap">
    <div class="axH"><h2>🔑 API Key Manager</h2><button class="axX" id="axClose">✕</button></div>
    <div class="axTabs">
      <button class="axTab on" data-t="keys">API Keys</button>
      <button class="axTab" data-t="docs">Dokumentasi</button>
    </div>
    <div class="axBody" id="axTabKeys">
      <p class="axLbl" style="margin-bottom:10px">Integrasi pembuatan akun SSH, VMess, VLESS, Trojan &amp; Shadowsocks via REST API.</p>
      <div class="axLbl">Nama Key</div>
      <input class="axIn" id="axName" placeholder="mis. bot-telegram, reseller-panel">
      <div class="axLbl" style="margin-top:14px">Masa Aktif (hari)</div>
      <div class="axRow">
        <input class="axIn" id="axDays" type="number" min="1" placeholder="kosong = unlimited" style="flex:1;min-width:130px">
        <button class="axChip" data-d="1">1</button>
        <button class="axChip" data-d="2">2</button>
        <button class="axChip" data-d="3">3</button>
        <button class="axChip" data-d="7">7</button>
        <button class="axChip" data-d="30">30</button>
        <button class="axChip" data-d="">∞</button>
      </div>
      <button class="axPri" id="axAdd" style="width:100%;margin-top:16px">+ Generate Key</button>
      <div class="axKey" id="axNew"></div>
      <div class="axCop" id="axCopied">✓ Key tersalin ke clipboard</div>
      <table class="axT"><thead><tr><th>Key</th><th>Masa Aktif</th><th>Pakai</th><th style="text-align:right">Aksi</th></tr></thead>
      <tbody id="axTb"></tbody></table>
      <p class="axNote">🔐 Key hanya ditampilkan <b>sekali</b> saat dibuat atau diganti — simpan segera.</p>
    </div>
    <div class="axBody" id="axTabDocs" style="display:none"></div>
  </div>`;
  document.body.appendChild(ov);

  const $ = (i) => document.getElementById(i);
  const H = () => ({ "Content-Type": "application/json", Authorization: "Bearer " + (localStorage.token || "") });
  const jt = async (r) => { const t = await r.text(); try { return JSON.parse(t); } catch (e) { return { detail: t }; } };

  // ---- theme sync (ikut class chakra-ui-dark di <html>) ----
  function syncTheme() {
    const dark = document.documentElement.classList.contains("chakra-ui-dark") ||
                 document.documentElement.getAttribute("data-theme") === "dark";
    ov.classList.toggle("axDark", dark);
    btn.style.borderColor = dark ? "#4a5568" : "#e2e8f0";
    btn.style.color = dark ? "#e2e8f0" : "#1a202c";
    btn.style.background = dark ? "transparent" : "transparent";
    btn.dataset.hover = dark ? "#4a5568" : "#edf2f7";
  }
  new MutationObserver(syncTheme).observe(document.documentElement, { attributes: true, attributeFilter: ["class", "data-theme"] });
  syncTheme();

  // ---- tabs ----
  ov.querySelector(".axTabs").addEventListener("click", (e) => {
    const b = e.target.closest(".axTab"); if (!b) return;
    ov.querySelectorAll(".axTab").forEach(t => t.classList.toggle("on", t === b));
    $("axTabKeys").style.display = b.dataset.t === "keys" ? "" : "none";
    $("axTabDocs").style.display = b.dataset.t === "docs" ? "" : "none";
    if (b.dataset.t === "docs") renderDocs();
  });

  // ---- chips hari ----
  ov.querySelectorAll(".axChip").forEach(c => c.onclick = () => {
    ov.querySelectorAll(".axChip").forEach(x => x.classList.remove("on"));
    c.classList.add("on");
    $("axDays").value = c.dataset.d;
  });

  // ---- keys ----
  async function load() {
    const d = await jt(await fetch("/apix/keys", { headers: H() }));
    const tb = $("axTb");
    if (d.detail) { tb.innerHTML = `<tr><td colspan="4" class="axEmpty">${d.detail}</td></tr>`; return; }
    if (!(d.keys || []).length) { tb.innerHTML = `<tr><td colspan="4" class="axEmpty">Belum ada API key</td></tr>`; return; }
    tb.innerHTML = "";
    d.keys.forEach((k) => {
      const tr = document.createElement("tr");
      const exp = k.expires_at
        ? new Date(k.expires_at * 1000).toLocaleDateString("id-ID", { day: "2-digit", month: "short", year: "numeric" })
        : "Unlimited";
      const pill = k.expired ? '<span class="axPill wr">expired</span>' : (k.enabled ? '<span class="axPill on">aktif</span>' : '<span class="axPill off">nonaktif</span>');
      tr.innerHTML = `
        <td><b>${k.name}</b> ${pill}<br><span class="axMono axMut" data-masked="${k.id}">${k.key}</span></td>
        <td>${exp}</td>
        <td>${k.calls}x</td>
        <td><div class="axAct">
          <button class="axSec" data-a="copy" data-id="${k.id}">Salin</button>
          <button class="axSec" data-a="show" data-id="${k.id}">Lihat</button>
          <button class="axSec" data-a="rot" data-id="${k.id}">Ganti</button>
          <button class="axSec" data-a="tog" data-id="${k.id}">${k.enabled ? "Nonaktifkan" : "Aktifkan"}</button>
          <button class="axSec red" data-a="del" data-id="${k.id}">Hapus</button>
        </div></td>`;
      tr._fullKey = k.full_key || null;
      tb.appendChild(tr);
    });
    tb._keys = d.keys;
  }
  $("axTabKeys").addEventListener("click", async (e) => {
    const b = e.target.closest("button[data-a]"); if (!b) return;
    const id = b.dataset.id, a = b.dataset.a;
    const tb = $("axTb");
    const krow = (tb._keys || []).find(k => String(k.id) === id);
    if (a === "copy") {
      let full = krow && krow.full_key;
      if (full) {
        try { await navigator.clipboard.writeText(full); }
        catch (err) {
          const ta = document.createElement("textarea"); ta.value = full;
          document.body.appendChild(ta); ta.select(); document.execCommand("copy"); ta.remove();
        }
        b.textContent = "✓ Tersalin"; setTimeout(() => b.textContent = "Salin", 1500);
      } else {
        alert("Full key tidak tersedia untuk key lama — gunakan Ganti (rotate) untuk buat key baru.");
      }
    }
    if (a === "show") {
      const span = tb.querySelector(`span[data-masked="${id}"]`);
      if (krow && krow.full_key && span) {
        const showing = span.dataset.showing === "1";
        span.textContent = showing ? krow.key : krow.full_key;
        span.dataset.showing = showing ? "0" : "1";
        b.textContent = showing ? "Lihat" : "Sembunyi";
      } else alert("Full key tidak tersedia untuk key lama — gunakan Ganti.");
    }
    if (a === "rot" && confirm("Ganti key ini? Key lama langsung mati.")) {
      const d = await jt(await fetch("/apix/keys/rotate", { method: "POST", headers: H(), body: JSON.stringify({ id: +id }) }));
      showNew(d); load();
    }
    if (a === "tog") { await fetch("/apix/keys/toggle", { method: "POST", headers: H(), body: JSON.stringify({ id: +id }) }); load(); }
    if (a === "del" && confirm("Hapus key ini permanen?")) { await fetch("/apix/keys?id=" + id, { method: "DELETE", headers: H() }); load(); }
  });
  function showNew(d) {
    if (!d.key) { alert(d.detail || "gagal"); return; }
    const el = $("axNew"); el.style.display = "block"; el.textContent = d.key;
    navigator.clipboard && navigator.clipboard.writeText(d.key).catch(() => {});
    $("axCopied").style.display = "block"; setTimeout(() => $("axCopied").style.display = "none", 2500);
  }
  $("axAdd").onclick = async () => {
    const btn0 = $("axAdd"); btn0.disabled = true;
    const d = $("axDays").value.trim();
    const days = d && +d > 0 ? +d : null;
    const exp = days ? Math.floor(Date.now() / 1000) + days * 86400 : null;
    const r = await jt(await fetch("/apix/keys", { method: "POST", headers: H(),
      body: JSON.stringify({ name: $("axName").value || "key", expires_at: exp }) }));
    showNew(r); load(); btn0.disabled = false;
  };

  // ---- docs + try it ----
  const ENDPOINTS = [
    { g: "🔑 Server" },
    { m: "GET",  n: "System info", path: "/apix/system", desc: "Stats server (memori, CPU, jumlah user)" },
    { g: "➕ Buat Akun Proxy" },
    { m: "POST", n: "Create VMess", path: "/apix/createvmess", desc: "Bikin akun VMess",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"quota_gb", label:"Quota (GB)", type:"number", ph:"kosong = unlimited"},
        {k:"days", label:"Masa Aktif (hari)", type:"number", ph:"kosong = unlimited"},
        {k:"limit_ip", label:"Limit IP", type:"number", ph:"kosong = unlimited"},
      ]},
    { m: "POST", n: "Create VLESS", path: "/apix/createvless", desc: "Bikin akun VLESS",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"quota_gb", label:"Quota (GB)", type:"number", ph:"kosong = unlimited"},
        {k:"days", label:"Masa Aktif (hari)", type:"number", ph:"kosong = unlimited"},
        {k:"limit_ip", label:"Limit IP", type:"number", ph:"kosong = unlimited"},
      ]},
    { m: "POST", n: "Create Trojan", path: "/apix/createtrojan", desc: "Bikin akun Trojan",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"quota_gb", label:"Quota (GB)", type:"number", ph:"kosong = unlimited"},
        {k:"days", label:"Masa Aktif (hari)", type:"number", ph:"kosong = unlimited"},
        {k:"limit_ip", label:"Limit IP", type:"number", ph:"kosong = unlimited"},
      ]},
    { m: "POST", n: "Create Shadowsocks", path: "/apix/createshadowsocks", desc: "Bikin akun Shadowsocks",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"quota_gb", label:"Quota (GB)", type:"number", ph:"kosong = unlimited"},
        {k:"days", label:"Masa Aktif (hari)", type:"number", ph:"kosong = unlimited"},
        {k:"limit_ip", label:"Limit IP", type:"number", ph:"kosong = unlimited"},
      ]},
    { g: "👤 Kelola Akun Proxy" },
    { m: "GET",  n: "Cek VMess", path: "/apix/getvmess", qs:"username", desc: "Status / pakai / quota / expired / sub URL", fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "GET",  n: "Cek VLESS", path: "/apix/getvless", qs:"username", desc: "", fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "GET",  n: "Cek Trojan", path: "/apix/gettrojan", qs:"username", desc: "", fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "GET",  n: "List Semua User", path: "/apix/users", desc: "Semua user proxy" },
    { m: "POST", n: "Renew VMess", path: "/apix/renewvmess", desc: "Perpanjang masa aktif (+quota opsional)",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"days", label:"Tambah Hari", type:"number", req:true, ph:"30"},
        {k:"quota_gb", label:"Quota Baru (GB)", type:"number", ph:"kosong = tetap"},
      ]},
    { m: "POST", n: "Renew VLESS", path: "/apix/renewvless", desc: "",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"days", label:"Tambah Hari", type:"number", req:true, ph:"30"},
        {k:"quota_gb", label:"Quota Baru (GB)", type:"number", ph:"kosong = tetap"},
      ]},
    { m: "POST", n: "Renew Trojan", path: "/apix/renewtrojan", desc: "",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"days", label:"Tambah Hari", type:"number", req:true, ph:"30"},
        {k:"quota_gb", label:"Quota Baru (GB)", type:"number", ph:"kosong = tetap"},
      ]},
    { m: "POST", n: "Renew Shadowsocks", path: "/apix/renewshadowsocks", desc: "",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budi"},
        {k:"days", label:"Tambah Hari", type:"number", req:true, ph:"30"},
        {k:"quota_gb", label:"Quota Baru (GB)", type:"number", ph:"kosong = tetap"},
      ]},
    { m: "DELETE", n: "Hapus VMess", path: "/apix/delvmess", qs:"username", desc: "Hapus akun user" , fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "DELETE", n: "Hapus VLESS", path: "/apix/delvless", qs:"username", desc: "" , fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "DELETE", n: "Hapus Trojan", path: "/apix/deltrojan", qs:"username", desc: "" , fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "DELETE", n: "Hapus Shadowsocks", path: "/apix/delshadowsocks", qs:"username", desc: "" , fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { g: "🖥️ Akun SSH (Dropbear)" },
    { m: "POST", n: "Create SSH", path: "/apix/ssh", desc: "Bikin akun SSH",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budissh"},
        {k:"password", label:"Password", ph:"kosong = acak otomatis"},
        {k:"days", label:"Masa Aktif (hari)", type:"number", ph:"30"},
        {k:"limit_login", label:"Limit Login", type:"number", ph:"kosong = unlimited"},
      ]},
    { m: "GET",  n: "List SSH", path: "/apix/ssh", desc: "Semua akun SSH + status + koneksi info" },
    { m: "PUT",  n: "Renew SSH", path: "/apix/ssh", desc: "",
      fields: [
        {k:"username", label:"Username", req:true, ph:"budissh"},
        {k:"days", label:"Tambah Hari", type:"number", req:true, ph:"30"},
      ]},
    { m: "DELETE", n: "Hapus SSH", path: "/apix/ssh", qs:"username", desc: "" , fields: [{k:"username", label:"Username", req:true, ph:"budi"}] },
    { m: "POST", n: "Lock SSH", path: "/apix/ssh/lock", desc: "Kunci akun",
      fields: [{k:"username", label:"Username", req:true, ph:"budissh"}] },
    { m: "POST", n: "Unlock SSH", path: "/apix/ssh/unlock", desc: "",
      fields: [{k:"username", label:"Username", req:true, ph:"budissh"}] },
  ];

  function renderDocs() {
    const b = location.origin;
    const opts = ENDPOINTS.map((e, i) =>
      e.m ? `<option value="${i}" data-m="${e.m}" data-path="${e.path}">[${e.m}] ${e.n}</option>` : "").join("");
    $("axTabDocs").innerHTML = `
      <div class="axLbl">🧪 API Tester — isi key kamu, pilih endpoint, coba langsung</div>
      <div class="axCardless">
        <input class="axIn" id="axTryKey" placeholder="apx_... (API Key kamu)" style="margin-bottom:10px">
        <select class="axIn" id="axTryEp" style="margin-bottom:10px">${opts}</select>
        <div id="axTryFields" style="display:flex;flex-direction:column;gap:8px"></div>
        <button class="axPri" id="axTryGo" style="width:100%;margin-top:14px">🚀 Kirim Request</button>
        <div class="axLbl" style="margin-top:14px;display:none" id="axTryLbl">Response</div>
        <div class="axCode" id="axTryOut" style="display:none;max-height:280px;overflow:auto;margin-top:8px"></div>
      </div>
      <div class="axLbl" style="margin-top:20px">📋 Referensi Endpoint</div>
      ${(function(){
        let h = "";
        for (const e of ENDPOINTS) {
          if (e.g) { h += `<div class="axLbl" style="margin-top:16px;color:var(--ax-primary)">${e.g}</div>`; continue; }
          h += `<div style="margin:10px 0 2px"><b style="font-size:12.5px">${e.n}</b> <span class="axPill ${(e.m==="DELETE")?"off":(e.m==="GET"?"on":"wr")}" style="margin-left:6px">${e.m}</span></div>
          <div class="axCode">${e.m} ${b}${e.path}</div>`;
        }
        return h;
      })()}
      <div class="axLbl" style="margin-top:16px">ℹ️ Catatan</div>
      <p class="axNote">
      • Kolom kosong pada <b>Quota / Masa Aktif / Limit IP</b> = unlimited<br>
      • Respon create langsung berisi <b>subscription_url</b> — tinggal dikirim ke pelanggan<br>
      • Username: 3-32 karakter, huruf kecil/angka/underscore<br>
      • Semua endpoint butuh header <b>X-API-Key</b> — dapatkan di tab API Keys</p>`;
    bindTry();
  }

  function bindTry() {
    const sel = $("axTryEp"), wrap = $("axTryFields");
    const renderFields = () => {
      const e = ENDPOINTS[+sel.value];
      wrap.innerHTML = "";
      (e.fields || []).forEach(f => {
        const el = document.createElement("div");
        el.innerHTML = `<div class="axLbl" style="margin:0 0 4px">${f.label}${f.req ? ' <span style="color:var(--ax-red)">*</span>' : ''}</div>
          <input class="axIn" data-fk="${f.k}" data-num="${f.type==="number"?1:0}" placeholder="${f.ph || ""}" value="${f.req && f.k==="username" ? "" : ""}">`;
        wrap.appendChild(el);
      });
    };
    sel.onchange = renderFields; renderFields();

    $("axTryGo").onclick = async () => {
      const key = $("axTryKey").value.trim();
      const e = ENDPOINTS[+sel.value];
      const out = $("axTryOut"), lbl = $("axTryLbl");
      const headers = { "Content-Type": "application/json", "X-API-Key": key };

      // kumpulkan field
      const vals = {};
      for (const inp of wrap.querySelectorAll("input[data-fk]")) {
        vals[inp.dataset.fk] = inp.value.trim();
      }
      // validasi required
      for (const f of (e.fields || [])) {
        if (f.req && !vals[f.k]) {
          out.style.display = "block";
          out.innerHTML = `<span style="color:#f87171">⚠️ ${f.label} wajib diisi</span>`;
          lbl.style.display = "block";
          return;
        }
      }

      let path = e.path, body = null;
      const qsFields = (e.qs) ? [{k:e.qs}] : null;
      if (e.qs) {
        // GET/DELETE dengan query param
        const q = new URLSearchParams();
        for (const f of (e.fields || [])) {
          if (vals[f.k]) q.set(f.k, vals[f.k]);
        }
        if (e.qs && vals[e.qs]) q.set(e.qs, vals[e.qs]);
        const qs = q.toString();
        path = e.path + (qs ? "?" + qs : "");
      } else if (e.fields && ["POST", "PUT"].includes(e.m)) {
        body = {};
        for (const f of (e.fields || [])) {
          let v = vals[f.k];
          if (v === "" || v === undefined) continue;
          if (f.type === "number") v = +v;
          body[f.k] = v;
        }
        body = JSON.stringify(body);  // fetch butuh string, bukan object
      }

      $("axTryGo").disabled = true; $("axTryGo").textContent = "⏳ Mengirim...";
      const t0 = Date.now();
      try {
        const r = await fetch(path, { method: e.m, headers, body });
        const txt = await r.text();
        let pretty = txt;
        try { pretty = JSON.stringify(JSON.parse(txt), null, 2); } catch (err) {}
        const ms = Date.now() - t0;
        const col = r.ok ? "#4ade80" : "#f87171";
        out.innerHTML = `<span style="color:${col};font-weight:700">${r.status} ${r.statusText}</span> <span class="axMut">(${ms} ms)</span>\n${pretty}`;
      } catch (err) {
        out.innerHTML = `<span style="color:#f87171">❌ ${err.message}</span>`;
      }
      out.style.display = "block"; lbl.style.display = "block";
      $("axTryGo").disabled = false; $("axTryGo").textContent = "🚀 Kirim Request";
    };
  }

  // ---- open/close ----
  $("axClose").onclick = () => ov.style.display = "none";
  ov.onclick = (e) => { if (e.target === ov) ov.style.display = "none"; };
  btn.onclick = () => { syncTheme(); ov.style.display = "flex"; load(); };

  // mount di header, Sebelah tombol theme
  function mount() {
    const themeBtn = [...document.querySelectorAll("button[aria-label]")].find(b => (b.getAttribute("aria-label") || "").includes("theme"));
    if (themeBtn && themeBtn.parentElement) { themeBtn.parentElement.insertBefore(btn, themeBtn); return true; }
    return false;
  }
  const iv = setInterval(() => { if (mount()) { clearInterval(iv); syncTheme(); } }, 800);
  setTimeout(() => { clearInterval(iv); if (!btn.isConnected) document.body.appendChild(btn); }, 12000);
})();
