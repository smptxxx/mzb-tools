#!/bin/bash

set -euo pipefail

APP_DIR="/opt/marzban"
DATA_DIR="/var/lib/marzban"
CERT_DIR="$DATA_DIR/certs"
PATCH_DIR="$DATA_DIR/patch"
ENV_FILE="$APP_DIR/.env"
CLI_CONF="/etc/marzban-cli.conf"
LOG_INSTALL="/tmp/marzban-install.log"

GH_TOKEN="${2:-}"
GH_RAW="https://raw.githubusercontent.com/smptxxx/mzb-tools/main"
JSDELIVR="https://cdn.jsdelivr.net/gh/smptxxx/mzb-tools@main"
URL_XRAY_CONFIG="$GH_RAW/xray_config.json"
URL_CONFIG_PY="$GH_RAW/config.py"
URL_PACKAGE="$GH_RAW/mzb-tools.zip"
URL_WSSSH="$GH_RAW/ws-ssh.py"
URL_TEMPLATE="$GH_RAW/index.html"
URL_APIX="$GH_RAW/apix/app.py"
URL_APIX_SERVICE="$GH_RAW/apix/apix.service"
URL_APIX_INJECT="$GH_RAW/apix/apix-inject.js"

DROPBEAR_VERSION="2019.78"
DROPBEAR_BIN="/usr/local/sbin/dropbear"

log()  { printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '  Peringatan: %s\n' "$*" >&2; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

run() { "$@" >/dev/null 2>&1 || true; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 && return 0
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$1"
}

fetch() {
  # fallback jsDelivr -> raw.githubusercontent
  curl -fsSL "$1" -o "$2" || {
    ALT=$(echo "$1" | sed "s|$JSDELIVR|$GH_RAW|")
    [ "$ALT" = "$1" ] && die "Gagal unduh $1"
    curl -fsSL -H "Authorization: token ${GH_TOKEN}" "$ALT" -o "$2" || die "Gagal unduh $1"
  }
}

[ "$EUID" -eq 0 ] || die "Jalankan sebagai root"

export TZ="Asia/Jakarta"
run timedatectl set-timezone Asia/Jakarta

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
  read -rp "Masukkan domain (sudah diarahkan ke IP VPS): " DOMAIN < /dev/tty
fi
[ -n "$DOMAIN" ] || die "Domain wajib diisi"

log "[1/7] Install Marzban"

: > "$LOG_INSTALL"

(
  for _ in $(seq 1 180); do
    if grep -q "Application startup complete" "$LOG_INSTALL" 2>/dev/null; then
      sleep 2
      pkill -INT -f '[d]ocker.* logs' || true
      exit 0
    fi
    sleep 2
  done
) &
WATCHER=$!

bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install 2>&1 \
  | tee "$LOG_INSTALL" || true

kill "$WATCHER" 2>/dev/null || true

[ -f "$APP_DIR/docker-compose.yml" ] \
  || die "Install Marzban gagal, cek log: $LOG_INSTALL"

log "[2/7] Hentikan Marzban (port 80 dibutuhkan untuk sertifikat)"
marzban down || true

log "[3/7] Buat sertifikat TLS untuk $DOMAIN"
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
  curl -s https://get.acme.sh | sh -s email=admin@"$DOMAIN"
  "$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt
  "$HOME/.acme.sh/acme.sh" --issue --standalone -d "$DOMAIN" --keylength ec-256
  "$HOME/.acme.sh/acme.sh" --install-cert -d "$DOMAIN" --ecc \
    --fullchain-file "$CERT_DIR/fullchain.pem" \
    --key-file "$CERT_DIR/key.pem"
fi

log "[4/7] Unduh xray_config.json dan config.py"

mkdir -p "$PATCH_DIR"

fetch "$URL_XRAY_CONFIG" "$DATA_DIR/xray_config.json"
fetch "$URL_CONFIG_PY"   "$PATCH_DIR/config.py"

need_cmd python3
need_cmd unzip
need_cmd wget
need_cmd cron
need_cmd script

systemctl enable --now cron >/dev/null 2>&1 || true

PACKAGE_DIR="/tmp/mzb-tools-package"
PACKAGE_FILE="/tmp/mzb-tools.zip"

rm -rf "$PACKAGE_DIR" "$PACKAGE_FILE"
mkdir -p "$PACKAGE_DIR"

fetch "$URL_PACKAGE" "$PACKAGE_FILE"
unzip -q "$PACKAGE_FILE" -d "$PACKAGE_DIR" || die "Gagal ekstrak $PACKAGE_FILE"

PACKAGE_ROOT="$PACKAGE_DIR"
if   [ -d "$PACKAGE_DIR/mzb-tools" ]; then PACKAGE_ROOT="$PACKAGE_DIR/mzb-tools"
elif [ -d "$PACKAGE_DIR/marzban"  ]; then PACKAGE_ROOT="$PACKAGE_DIR/marzban"
fi

for script in "$PACKAGE_ROOT"/*; do
  [ -f "$script" ] || continue

  case "$(basename "$script")" in
    *.sh|addws|addvl|addtr|renewws|renewvl|renewtr|dellws|dellvl|delltr|\
    trialws|trialvl|trialtr|cekws|cekvl|cektr|lockws|lockvl|locktr|\
    unlockws|unlockvl|unlocktr|menulock|setbot|setunlock|menu|addssh|\
    renewssh|dellssh|trialssh|cekssh|lockssh|unlockssh|bannerssh|setdomain|\
    menubackup|backup|restore|mzb-tools-core.sh)
      install -m 755 "$script" "/usr/local/bin/$(basename "$script")"
      ;;
  esac
done

[ -x /usr/local/bin/mzb-tools.sh ] \
  || die "mzb-tools.sh tidak ditemukan dalam paket"

install -m 755 /usr/local/bin/mzb-tools.sh /usr/local/bin/mzb-tools

rm -rf "$PACKAGE_DIR" "$PACKAGE_FILE"

log "[4b/7] Pasang SSH WebSocket"

if [ ! -x "$DROPBEAR_BIN" ] || \
   ! "$DROPBEAR_BIN" -V 2>&1 | grep -q "Dropbear v${DROPBEAR_VERSION}"; then

  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential curl zlib1g-dev

  DROPBEAR_SRC="/tmp/dropbear-${DROPBEAR_VERSION}.tar.bz2"
  DROPBEAR_DIR="/tmp/dropbear-${DROPBEAR_VERSION}"

  curl -fsSL "https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VERSION}.tar.bz2" \
    -o "$DROPBEAR_SRC"

  rm -rf "$DROPBEAR_DIR"
  mkdir -p "$DROPBEAR_DIR"

  tar -xjf "$DROPBEAR_SRC" -C /tmp

  (
    cd "$DROPBEAR_DIR"
    ./configure --prefix=/usr/local
    make -j"$(nproc)"
    make install
  )

  rm -rf "$DROPBEAR_SRC" "$DROPBEAR_DIR"
fi

systemctl disable --now dropbear >/dev/null 2>&1 || true

grep -qx '/bin/false' /etc/shells || echo '/bin/false' >> /etc/shells

mkdir -p /etc/dropbear

fetch "$URL_WSSSH" /usr/local/bin/ws-ssh.py
chmod +x /usr/local/bin/ws-ssh.py

cat > /etc/systemd/system/dropbear-ws.service <<'UNIT_EOF'
[Unit]
Description=Dropbear (127.0.0.1:109)
After=network.target

[Service]
ExecStart=/usr/local/sbin/dropbear -F -E -R -w -p 127.0.0.1:109
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
UNIT_EOF

cat > /etc/systemd/system/ws-ssh.service <<'UNIT_EOF'
[Unit]
Description=Proxy SSH WebSocket
After=network.target dropbear-ws.service

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws-ssh.py -b 127.0.0.1 -p 10015
Restart=always

[Install]
WantedBy=multi-user.target
UNIT_EOF

systemctl daemon-reload
systemctl enable --now dropbear-ws ws-ssh

log "Pasang UDPGW (127.0.0.1:7300)"

if ! command -v badvpn-udpgw >/dev/null 2>&1; then
  apt-get update -y >/dev/null 2>&1 || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y badvpn >/dev/null 2>&1 || true
fi

if ! command -v badvpn-udpgw >/dev/null 2>&1; then
  echo "  paket badvpn tidak tersedia, mencoba kompilasi dari sumber..."

  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake git >/dev/null 2>&1 || true

  rm -rf /tmp/badvpn-src

  if git clone --depth 1 https://github.com/ambrop72/badvpn /tmp/badvpn-src >/dev/null 2>&1; then
    mkdir -p /tmp/badvpn-src/build
    (
      cd /tmp/badvpn-src/build &&
      cmake .. \
        -DBUILD_NOTHING_BY_DEFAULT=1 \
        -DBUILD_UDPGW=1 \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 >/dev/null 2>&1 &&
      make install >/dev/null 2>&1
    ) || true
  fi

  rm -rf /tmp/badvpn-src
fi

UDPGW_BIN="$(command -v badvpn-udpgw || true)"

if [ -n "$UDPGW_BIN" ]; then
  cat > /etc/systemd/system/udpgw.service <<UNIT_EOF
[Unit]
Description=BadVPN UDPGW (127.0.0.1:7300)
After=network.target

[Service]
ExecStart=$UDPGW_BIN --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always

[Install]
WantedBy=multi-user.target
UNIT_EOF

  systemctl daemon-reload
  systemctl enable udpgw >/dev/null 2>&1 || true
  systemctl restart udpgw

  sleep 1

  if ss -tln 2>/dev/null | grep -q '127.0.0.1:7300'; then
    echo "  UDPGW aktif di 127.0.0.1:7300"
  else
    warn "UDPGW belum mendengarkan di port 7300"
  fi
else
  warn "badvpn-udpgw gagal dipasang, UDPGW dilewati"
fi

/usr/local/bin/mzb-tools banner-init || warn "banner SSH belum terpasang"
/usr/local/bin/mzb-tools autostart on

cat > /etc/logrotate.d/marzban-access <<'LOGROTATE_EOF'
/var/lib/marzban/access.log {
    daily
    maxsize 50M
    rotate 1
    missingok
    notifempty
    copytruncate
    compress
}
LOGROTATE_EOF

if ! grep -q "patch/config.py" "$APP_DIR/docker-compose.yml"; then
  sed -i "\|- /var/lib/marzban:/var/lib/marzban|a\\      - /var/lib/marzban/patch/config.py:/code/app/xray/config.py" \
    "$APP_DIR/docker-compose.yml"
fi

if [ ! -f /swapfile ]; then
  log "Tuning ringan: swap 2GB + matikan service berat"
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  echo "vm.swappiness=10" > /etc/sysctl.d/99-swap.conf
  sysctl vm.swappiness=10 >/dev/null
  for svc in snapd snapd.socket packagekit multipathd unattended-upgrades apt-daily apt-daily-upgrade; do
    systemctl disable --now $svc 2>/dev/null || true
  done
fi

log "[5/7] Atur .env"

touch "$ENV_FILE"

if [ -s "$ENV_FILE" ] && [ -n "$(tail -c 1 "$ENV_FILE")" ]; then
  printf '\n' >> "$ENV_FILE"
fi

set_env() {
  local key="$1" value="$2" escaped
  escaped=$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g')

  if grep -qE "^#?[[:space:]]*$key[[:space:]]*=" "$ENV_FILE"; then
    sed -i -E "s|^#?[[:space:]]*$key[[:space:]]*=.*|$key=\"$escaped\"|" "$ENV_FILE"
  else
    printf '%s\n' "$key=\"$value\"" >> "$ENV_FILE"
  fi
}

set_env XRAY_JSON "/var/lib/marzban/xray_config.json"

sed -i '/^UVICORN_SSL_CERTFILE[[:space:]]*=/d;/^UVICORN_SSL_KEYFILE[[:space:]]*=/d' "$ENV_FILE"

set_env UVICORN_HOST "127.0.0.1"
set_env UVICORN_PORT "8000"
set_env XRAY_SUBSCRIPTION_URL_PREFIX "https://$DOMAIN"
set_env UVICORN_WORKERS "1"
set_env UVICORN_ACCESS_LOG "false"

mkdir -p "$DATA_DIR/templates/subscription"

wget -q -N -P "$DATA_DIR/templates/subscription/" "$URL_TEMPLATE"

set_env CUSTOM_TEMPLATES_DIRECTORY "/var/lib/marzban/templates/"
set_env SUBSCRIPTION_PAGE_TEMPLATE "subscription/index.html"

sed -i '/^SUDO_USERNAME[[:space:]]*=/d;/^SUDO_PASSWORD[[:space:]]*=/d' "$ENV_FILE"

ADMIN_USER="admin"
ADMIN_PASS=""
ADMIN_NEW=""

{
  printf 'DOMAIN=%q\n'        "$DOMAIN"
  printf 'API_URL=%q\n'       "http://127.0.0.1:8000"
  printf 'TRIAL_MINUTES=%q\n' "60"
  printf 'TRIAL_GB=%q\n'      "1"
} > "$CLI_CONF"

chmod 600 "$CLI_CONF"

log "[6/7] Pasang APIX — API Gateway + Key Manager di dashboard"

mkdir -p "$DATA_DIR/apix"
fetch "$URL_APIX" "$DATA_DIR/apix/app.py"
fetch "$URL_APIX_SERVICE" "/etc/systemd/system/apix.service"
fetch "$URL_APIX_INJECT" "$DATA_DIR/apix/apix-inject.js"

sed -i "s|Environment=MZB_ADMIN_USER=.*|Environment=MZB_ADMIN_USER=$ADMIN_USER|" /etc/systemd/system/apix.service 2>/dev/null || true

python3 -m venv /usr/local/bin/apix-venv 2>/dev/null || true
/usr/local/bin/apix-venv/bin/pip -q install fastapi "uvicorn[standard]" >/dev/null 2>&1

systemctl daemon-reload
systemctl enable --now apix

log "Sisipkan tombol API Keys ke dashboard Marzban"

token_wait=0
until curl -s -o /dev/null http://127.0.0.1:8000/dashboard/ 2>/dev/null; do
  sleep 2; token_wait=$((token_wait+1))
  [ $token_wait -gt 30 ] && break
done

ADMIN_TMP_USER="${MZB_ADMIN_USER:-$ADMIN_USER}"
if [ -f "$CLI_CONF" ] && grep -q "ADMIN_USER=" "$CLI_CONF"; then
  ADMIN_TMP_USER="$(grep '^ADMIN_USER=' "$CLI_CONF" | cut -d= -f2 | tr -d "'\"")"
fi

docker exec marzban-marzban-1 mkdir -p /code/app/dashboard/build/statics 2>/dev/null || true
docker cp "$DATA_DIR/apix/apix-inject.js" marzban-marzban-1:/code/app/dashboard/build/statics/apix-inject.js
docker exec marzban-marzban-1 bash -c "cd /code/app/dashboard/build && grep -q apix-inject index.html || sed -i 's#</head>#  <script src=\"/statics/apix-inject.js\" defer></script>\n  </head>#'" index.html 2>/dev/null || \
docker exec marzban-marzban-1 bash -c "cd /code/app/dashboard/build && grep -q apix-inject index.html || sed -i 's#</head>#  <script src=\"/statics/apix-inject.js\" defer></script>\n  </head>#' index.html"

# simpan kredensial utk APIX (password admin anonim diset saat step 7)
grep -q "MZB_ADMIN_USER" /etc/systemd/system/apix.service || \
  sed -i "/\[Service\]/a Environment=MZB_ADMIN_USER=$ADMIN_TMP_USER" /etc/systemd/system/apix.service

log "[7/7] Jalankan Marzban"

marzban up -n

echo "Menunggu Marzban siap..."

MARZBAN_READY="no"
for _ in $(seq 1 60); do
  if marzban cli admin list >/dev/null 2>&1; then
    MARZBAN_READY="yes"
    echo "Marzban siap."
    break
  fi
  sleep 2
done

[ "$MARZBAN_READY" = "yes" ] || die "Marzban belum siap setelah menunggu 120 detik."

if marzban cli admin list 2>/dev/null | grep -qE '(^|[[:space:]])admin([[:space:]]|$)'; then
  echo "Admin sudah ada."
  echo "Password admin yang sudah ada tidak diubah."

  sed -i '/^ADMIN_USER=/d;/^ADMIN_PASS=/d' "$CLI_CONF"
  printf 'ADMIN_USER=%q\n' "$ADMIN_USER" >> "$CLI_CONF"
else
  echo "Admin belum ada."
  echo "Membuat admin baru..."

  ADMIN_PASS="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20)"

  if printf '%s\n%s\n%s\n\n\n' \
      "$ADMIN_USER" \
      "$ADMIN_PASS" \
      "$ADMIN_PASS" \
    | script -qec "marzban cli admin create --sudo" /dev/null \
    >/tmp/marzban-admin-create.log 2>&1; then

    ADMIN_NEW="yes"

    sed -i '/^ADMIN_USER=/d;/^ADMIN_PASS=/d' "$CLI_CONF"
    printf 'ADMIN_USER=%q\n' "$ADMIN_USER" >> "$CLI_CONF"
    printf 'ADMIN_PASS=%q\n' "$ADMIN_PASS" >> "$CLI_CONF"

    echo "Admin '$ADMIN_USER' berhasil dibuat."
  else
    echo
    echo "GAGAL membuat admin '$ADMIN_USER'."
    cat /tmp/marzban-admin-create.log
    exit 1
  fi
fi

# set password admin ke APIX setelah diketahui
if [ "$ADMIN_NEW" = "yes" ]; then
  sed -i "s|Environment=MZB_ADMIN_USER=.*|Environment=MZB_ADMIN_USER=$ADMIN_USER|" /etc/systemd/system/apix.service
  sed -i "s|Environment=MZB_ADMIN_PASS=.*|Environment=MZB_ADMIN_PASS=$ADMIN_PASS|" /etc/systemd/system/apix.service
  systemctl daemon-reload && systemctl restart apix
fi

# pastikan apix service punya MZB_ADMIN_PASS dari CLI_CONF bila sudah ada
if [ -f "$CLI_CONF" ] && grep -q "^ADMIN_PASS=" "$CLI_CONF"; then
  EXISTING_PASS="$(grep '^ADMIN_PASS=' "$CLI_CONF" | cut -d= -f2 | tr -d "'\"")"
  grep -q "MZB_ADMIN_PASS" /etc/systemd/system/apix.service && \
    sed -i "s|Environment=MZB_ADMIN_PASS=.*|Environment=MZB_ADMIN_PASS=$EXISTING_PASS|" /etc/systemd/system/apix.service || \
    sed -i "/\[Service\]/a Environment=MZB_ADMIN_PASS=$EXISTING_PASS" /etc/systemd/system/apix.service
  systemctl daemon-reload && systemctl restart apix
fi

echo
echo "Selesai."
echo "Username : $ADMIN_USER"

if [ "$ADMIN_NEW" = "yes" ]; then
  echo "Password : $ADMIN_PASS"
else
  echo "Password : admin sudah ada, tidak diubah."
fi

echo
echo "APIX (API Gateway) : aktif — /apix di dashboard"
echo "Dashboard          : https://$DOMAIN/dashboard/"
echo
read -rp "Tekan Enter untuk reboot..." < /dev/tty
reboot
