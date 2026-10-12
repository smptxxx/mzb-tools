# MZB-TOOLS — Auto Installer Marzban

Auto installer Marzban + tools manajemen akun (VMess/VLess/Trojan/SSH) untuk VPS Ubuntu/Debian.

## Fitur
- Install Marzban (Docker) + SSL otomatis (acme.sh)
- Tools CLI: buat/renew/hapus/cek akun VMess, VLess, Trojan & SSH
- Akun trial auto-delete, lock/unlock, notifikasi Telegram
- SSH over WebSocket (ws-ssh) + Dropbear + UDPGW

## Auto Install

Jalankan sebagai root, satu perintah:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/smptxxx/mzb-tools/main/install.sh) domain.com ghp_TOKENGITHUB
```

Ganti:
- `domain.com` → domain kamu yang sudah diarahkan (A record) ke IP VPS
- `ghp_TOKENGITHUB` → GitHub Personal Access Token kamu (repo ini butuh auth)

Contoh:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/smptxxx/mzb-tools/main/install.sh) nexusdev.my.id ghp_xxxxxxxxxxxx
```

Atau mode interaktif (domain ditanya saat install):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/smptxxx/mzb-tools/main/install.sh) "" ghp_TOKENGITHUB
```

## Setelah Install

| Perintah | Fungsi |
|----------|--------|
| `menu` | Menu utama Marzban Tools |
| `addws` / `addvl` / `addtr` | Buat akun VMess/VLess/Trojan |
| `addssh` | Buat akun SSH |
| `cekws` | Cek user online |
| `setbot` | Setting bot Telegram |
| `menulock` | Menu lock/unlock akun |

## Port yang Digunakan

| Port | Layanan |
|------|---------|
| 443 | Xray TLS (VMess/VLess/Trojan + WebSocket) |
| 80 | Xray non-TLS |
| 109 | Dropbear SSH |
| 7300 | UDPGW |
| 8000 | Panel Marzban (via /dashboard) |

## Persyaratan
- VPS Ubuntu 20.04+ / Debian 10+ (fresh)
- Akses root
- Domain sudah di-pointing ke IP VPS
- GitHub Personal Access Token (scope: repo)

## Lisensi
Private — hanya untuk penggunaan pribadi.
