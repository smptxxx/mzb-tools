#!/usr/bin/env python3
"""Hapus tombol Donasi + GitHub Star + footer credit dari dashboard Marzban (dijalankan DI DALAM container).
Auto-detect: cari index.*.js yang direferensikan build/index.html, patch in place dengan cache-bust rename."""
import json, re, subprocess, os, glob

BUILD = None
# cari build dir
for cand in glob.glob("/code/app/dashboard*/build*"):
    if os.path.exists(cand + "/index.html"):
        BUILD = cand
if not BUILD:
    BUILD = "/code/app/dashboard/build"

idx = open(f"{BUILD}/index.html", encoding="utf-8").read()
m = re.search(r'src="/statics/(index\.[a-z0-9]+\.js)"', idx)
if not m:
    print("POLA JS TIDAK KETEMU di index.html — mungkin sudah pernah di-patch")
    m2 = re.search(r'src="/statics/(index\.[a-z0-9]+\.js)"', idx)
    print(idx[:2000])
    raise SystemExit(1)

jsname = m.group(1)
jsp = f"{BUILD}/statics/{jsname}"
s = open(jsp, encoding="utf-8").read()
orig = len(s)
edits = 0

# 1) Donate menu item
d1 = ',e(pr,{to:Ds,target:"_blank",children:r(Se,{maxW:"170px",fontSize:"sm",icon:e(Ns,{}),position:"relative",onClick:C,children:[w("header.donation")," ",h&&e(Ir,{top:"3",right:"2"})]})})'
if d1 in s: s = s.replace(d1, ""); edits += 1

# 2) GitHub star button
mstar = re.search(r',e\(v,\{css:\{direction:"ltr"\}[^\n]*?Star Marzban on GitHub[^\n]*?\)\}\)', s)
if mstar:
    s = s.replace(mstar.group(0), "", 1); edits += 1

# 3) Footer credit
d3 = 'children:[e(ur,{color:"blue.400",href:pn,children:"Marzban"}),n?` (v${n}), `:", ","Made with \\u2764\\uFE0F in"," ",e(ur,{color:"blue.400",href:vs,children:"Gozargah"})]'
if d3 in s:
    s = s.replace(d3, 'children:""'); edits += 1

# fallback generik (kalau variabel beda): hapus href ke Marzban#donation
if "#donation" in s:
    s = re.sub(r',e\([A-Za-z_$]+,\{to:[A-Za-z_$]+,[^)]*?Marzban#donation[^\n]*?\)\)', '', s, count=1)
    edits += 1

assert s.count("(") == s.count(")") and s.count("{") == s.count("}"), "UNBALANCED"
newname = jsname.replace(".", ".bosfix.") if ".bosfix." not in jsname else jsname
# cache-bust: rename
newname = re.sub(r"(index\.[a-z0-9]+)(\.js)", r"\1.bosfix\2", jsname)
open(f"{BUILD}/statics/{newname}", "w", encoding="utf-8").write(s)
os.remove(jsp)
idx2 = idx.replace(jsname, newname)
open(f"{BUILD}/index.html", "w", encoding="utf-8").write(idx2)
print(f"Patched: {edits} edit(s), {jsname} -> {newname}, {orig} -> {len(s)} bytes, BUILD={BUILD}")
