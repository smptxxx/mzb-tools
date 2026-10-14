#!/bin/bash

UI_W=57
UI_LW=14
UI_ESC=$'\033'
UI_B=$'\001'
UI_E=$'\002'
CYAN=$'\033[1;36m'
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
WHITE=$'\033[1;37m'
BGRED=$'\033[41;1;37m'
NC=$'\033[0m'

ui_repeat() {
    local out
    printf -v out '%*s' "$1" ''
    printf '%s' "${out// /$2}"
}

ui_len() {
    local s n c
    s=$(printf '%s' "$1" | sed "s/${UI_ESC}\[[0-9;]*m//g")
    local LC_ALL=C
    n=${#s}
    c=${s//[^$'\x80'-$'\xbf']/}
    printf '%s' $((n - ${#c}))
}

ui_pad() {
    local len
    len=$(ui_len "$1")
    printf '%s' "$1"
    (( len < $2 )) && printf '%*s' $(( $2 - len )) ''
}

ui_center() {
    local len left
    len=$(ui_len "$1")
    left=$(( ($2 - len) / 2 ))
    (( left < 0 )) && left=0
    printf '%*s' "$left" ''
    ui_pad "$1" $(( $2 - left ))
}

box_top() { printf ' %s┌%s┐%s\n' "$CYAN" "$(ui_repeat "$UI_W" ─)" "$NC"; }
box_mid() { printf ' %s├%s┤%s\n' "$CYAN" "$(ui_repeat "$UI_W" ─)" "$NC"; }
box_bottom() { printf ' %s└%s┘%s\n' "$CYAN" "$(ui_repeat "$UI_W" ─)" "$NC"; }

box_top2() {
    local half=$(( (UI_W - 1) / 2 ))
    printf ' %s┌%s┬%s┐%s\n' "$CYAN" "$(ui_repeat "$half" ─)" "$(ui_repeat "$half" ─)" "$NC"
}

box_bottom2() {
    local half=$(( (UI_W - 1) / 2 ))
    printf ' %s└%s┴%s┘%s\n' "$CYAN" "$(ui_repeat "$half" ─)" "$(ui_repeat "$half" ─)" "$NC"
}

box_header() {
    box_top
    printf ' %s│%s%s%s%s│%s\n' "$CYAN" "$BGRED" "$(ui_center "$1" "$UI_W")" "$NC" "$CYAN" "$NC"
    box_bottom
}

box_line() {
    local len
    len=$(ui_len "$1")
    if (( len <= UI_W - 2 )); then
        printf ' %s│%s %s%s %s│%s\n' "$CYAN" "$NC" "$(ui_pad "$1" $(( UI_W - 2 )))" "$NC" "$CYAN" "$NC"
    else
        printf ' %s│%s %s%s\n' "$CYAN" "$NC" "$1" "$NC"
    fi
}

box_text() { box_line "${WHITE}$1"; }
box_link() { box_line "${GREEN}$1"; }
box_center() { box_line "$(ui_center "${WHITE}$1" $(( UI_W - 2 )))"; }

box_kv() {
    local len
    len=$(ui_len "$2")
    if (( UI_LW + 3 + len > UI_W - 2 )); then
        box_text "$1 :"
        box_link "$2"
    else
        box_line "${WHITE}$(printf '%-*s' "$UI_LW" "$1") :${GREEN} $2"
    fi
}

box_table_head() {
    box_line "${WHITE}$(printf '%-5s %-20s %s' "$1" "$2" "$3")"
}

box_table_row() {
    box_line "${RED}$(printf '%-5s' "$1")${NC} ${GREEN}$(printf '%-20s' "$2") $3${4:+ ${RED}$4}"
}

ui_item() { printf '%s%-4s%s %s%s%s' "$RED" "[$1]" "$NC" "$WHITE" "$2" "$NC"; }

box_menu2() {
    local half=$(( (UI_W - 1) / 2 )) left right
    left=$(ui_pad "$(ui_item "$1" "$2")" $(( half - 2 )))
    if [[ -n "$3" ]]; then
        right=$(ui_pad "$(ui_item "$3" "$4")" $(( half - 2 )))
    else
        right=$(ui_pad "" $(( half - 2 )))
    fi
    printf ' %s│%s %s %s│%s %s %s│%s\n' "$CYAN" "$NC" "$left" "$CYAN" "$NC" "$right" "$CYAN" "$NC"
}

print_success() { printf ' %s✓ %s%s\n' "$GREEN" "$1" "$NC"; }
print_error() { printf ' %s✗ %s%s\n' "$RED" "$1" "$NC"; }
print_warning() { printf ' %s! %s%s\n' "$RED" "$1" "$NC"; }
print_info() { printf ' %s»%s %s%s%s\n' "$CYAN" "$NC" "$WHITE" "$1" "$NC"; }

prompt_str() {
    local r="${UI_B}${RED}${UI_E}" w="${UI_B}${WHITE}${UI_E}" c="${UI_B}${CYAN}${UI_E}" n="${UI_B}${NC}${UI_E}"
    printf ' %s➤%s %s%s%s %s:%s ' "$r" "$n" "$w" "$1" "$n" "$c" "$n"
}

ui_pause() {
    read -n 1 -s -r -p "$(prompt_str "${1:-Press any key to continue}")"
}

CONF="/etc/marzban-cli.conf"
ENV_FILE="${ENV_FILE:-/opt/marzban/.env}"
STATE_DIR="/var/lib/marzban-cli"
TRIAL_LIST="$STATE_DIR/trial.list"
IPLIMIT_DB="$STATE_DIR/iplimit.db"
STRIKES_FILE="$STATE_DIR/iplimit.strikes"
IPLIMIT_LOG="/var/log/mzb-iplimit.log"
CRON_FILE="/etc/cron.d/mzb-tools"
AUTOLOCK_FILE="$STATE_DIR/autolock.list"
IPINFO_FILE="$STATE_DIR/ipinfo"
BACKUP_DIR="${BACKUP_DIR:-/root/backup}"
MZB_DATA="${MZB_DATA:-/var/lib/marzban}"
MZB_APP="${MZB_APP:-/opt/marzban}"
BACKUP_CRON="${BACKUP_CRON:-/etc/cron.d/mzb-backup}"
BACKUP_LOG="${BACKUP_LOG:-/var/log/mzb-backup.log}"
BACKUP_KEEP=7
BANNER_FILE="${BANNER_FILE:-/etc/dropbear/banner}"
BANNER_MAX=2000
DROPBEAR_UNIT="${DROPBEAR_UNIT:-/etc/systemd/system/dropbear-ws.service}"
DROPBEAR_BIN="${DROPBEAR_BIN:-/usr/local/sbin/dropbear}"
SSH_LIMIT_DB="$STATE_DIR/ssh-limit.db"
SSH_STRIKES="$STATE_DIR/ssh-limit.strikes"
SSH_AUTOLOCK="$STATE_DIR/ssh-autolock.list"

TRIAL_MINUTES=60
TRIAL_GB=1
TRIAL_IP=2
ONLINE_WINDOW=60
IP_WINDOW=120
IPLIMIT_STRIKES=1
ACCESS_LOG="/var/lib/marzban/access.log"
AUTO_UNLOCK="off"
AUTO_UNLOCK_MINUTES=30
TG_TOKEN=""
TG_CHATID=""
BK_TOKEN=""
BK_CHATID=""
BK_PASS=""
BK_AUTO="off"
BACKUP_HOUR=5
TG_API="${TG_API:-https://api.telegram.org}"

conf_set() {
    local k="$1" v="$2"
    touch "$CONF"
    chmod 600 "$CONF"
    sed -i "/^$k=/d" "$CONF"
    printf '%s=%q\n' "$k" "$v" >> "$CONF"
    printf -v "$k" '%s' "$v"
}

load_conf() {
    [[ -f "$CONF" ]] && source "$CONF"
    if [[ -z "$DOMAIN" || -z "$ADMIN_USER" || -z "$ADMIN_PASS" || -z "$API_URL" ]]; then
        setup_conf
    fi
}

setup_conf() {
    local d_def="" port scheme="http"
    clear
    box_header "SETUP MARZBAN TOOLS"
    echo ""
    if [[ -f "$ENV_FILE" ]]; then
        d_def=$(grep -E '^XRAY_SUBSCRIPTION_URL_PREFIX' "$ENV_FILE" | head -1 \
            | sed -E 's/^[^=]*=[[:space:]]*"?([^"]*)"?.*/\1/; s#https?://##; s#:[0-9]+$##; s#/$##')
        port=$(grep -E '^UVICORN_PORT' "$ENV_FILE" | head -1 | sed -E 's/^[^=]*=[[:space:]]*"?([0-9]+)"?.*/\1/')
        grep -qE '^UVICORN_SSL_CERTFILE' "$ENV_FILE" && scheme="https"
    fi
    port=${port:-8000}
    API_URL="${scheme}://127.0.0.1:${port}"

    read -rp "$(prompt_str "Domain${d_def:+ [$d_def]}")" -e DOMAIN
    DOMAIN=${DOMAIN:-$d_def}
    read -rp "$(prompt_str "Username admin Marzban")" -e ADMIN_USER
    read -rsp "$(prompt_str "Password admin Marzban")" ADMIN_PASS
    echo ""

    if [[ -z "$DOMAIN" || -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
        print_error "Domain, username, dan password wajib diisi"
        exit 1
    fi

    conf_set DOMAIN "$DOMAIN"
    conf_set API_URL "$API_URL"
    conf_set ADMIN_USER "$ADMIN_USER"
    conf_set ADMIN_PASS "$ADMIN_PASS"
    grep -q '^TRIAL_MINUTES=' "$CONF" || conf_set TRIAL_MINUTES "$TRIAL_MINUTES"
    grep -q '^TRIAL_GB=' "$CONF" || conf_set TRIAL_GB "$TRIAL_GB"
    grep -q '^TRIAL_IP=' "$CONF" || conf_set TRIAL_IP "$TRIAL_IP"
    ensure_cron
    print_success "Pengaturan disimpan di $CONF"
}

pj() {
    python3 -c 'import sys,json,os
d=json.load(sys.stdin)
P=os.environ.get("PROTO","")
print(eval(sys.argv[1]))' "$1" 2>/dev/null
}

api() {
    local r
    if [[ -n "$3" ]]; then
        r=$(curl -sk -m 20 -w '\n%{http_code}' -X "$1" "$API_URL$2" \
            -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$3")
    else
        r=$(curl -sk -m 20 -w '\n%{http_code}' -X "$1" "$API_URL$2" \
            -H "Authorization: Bearer $TOKEN")
    fi
    CODE="${r##*$'\n'}"
    BODY="${r%$'\n'*}"
    [[ "$CODE" =~ ^[0-9]{3}$ ]] || CODE="000"
}

login() {
    local r
    r=$(curl -sk -m 20 -w '\n%{http_code}' "$API_URL/api/admin/token" \
        --data-urlencode "username=$ADMIN_USER" --data-urlencode "password=$ADMIN_PASS")
    CODE="${r##*$'\n'}"
    BODY="${r%$'\n'*}"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        print_error "Login admin gagal (HTTP ${CODE:-000}). Cek Marzban berjalan dan login admin benar"
        print_info "Atur ulang dengan: mzb-tools setup"
        echo ""
        exit 1
    fi
    TOKEN=$(printf '%s' "$BODY" | pj 'd["access_token"]')
}

api_error() {
    local msg
    msg=$(printf '%s' "$BODY" | pj 'd.get("detail")')
    print_error "$1 (HTTP $CODE)${msg:+: $msg}"
}

marzban_log_hint() {
    local cname lines
    cname=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i marzban | head -1)
    [[ -n "$cname" ]] || return 0
    lines=$(docker logs --tail 80 "$cname" 2>&1 | grep -iE 'error|exception|traceback|locked|integrity|validation|constraint' | tail -n 5 | cut -c1-160)
    [[ -n "$lines" ]] || return 0
    print_info "Log Marzban terakhir:"
    printf '%s\n' "$lines"
}

api_delete_user() {
    # Hapus user. Return 0 jika akun sudah tidak ada. Coba ulang untuk error 5xx,
    # lalu cek langsung (GET) karena Marzban kadang membalas 500 padahal akun sudah terhapus.
    local u="$1" i last_code last_body
    DEL_NOTE=""
    for i in 1 2 3; do
        api DELETE "/api/user/$u"
        [[ "$CODE" == "200" || "$CODE" == "404" ]] && return 0
        [[ "$CODE" =~ ^5 ]] || return 1
        last_code="$CODE"; last_body="$BODY"
        sleep 1
    done
    api GET "/api/user/$u"
    if [[ "$CODE" == "404" ]]; then
        DEL_NOTE="Marzban membalas HTTP $last_code, tetapi akun sudah terhapus dari database"
        return 0
    fi
    CODE="$last_code"; BODY="$last_body"
    return 1
}

set_proto() {
    case "$1" in
        ws)
            PROTO="vmess"; TITLE="VMESS"; PATHW="/vmess-ws"
            TAGS='"VMess WS 443","VMess WS 80"' ;;
        vl)
            PROTO="vless"; TITLE="VLESS"; PATHW="/vless-ws"
            TAGS='"VLESS WS 443","VLESS WS 80"' ;;
        tr)
            PROTO="trojan"; TITLE="TROJAN"; PATHW="/trojan-ws"
            TAGS='"Trojan WS 443"' ;;
    esac
    export PROTO
    PATHENC="${PATHW//\//%2F}"
}

build_links() {
    local j1 j2
    case "$PROTO" in
        vmess)
            j1=$(printf '{"v":"2","ps":"%s","add":"%s","port":"443","id":"%s","aid":"0","net":"ws","path":"%s","type":"none","host":"%s","tls":"tls","sni":"%s"}' \
                "$user" "$DOMAIN" "$SECRET" "$PATHW" "$DOMAIN" "$DOMAIN")
            j2=$(printf '{"v":"2","ps":"%s","add":"%s","port":"80","id":"%s","aid":"0","net":"ws","path":"%s","type":"none","host":"%s","tls":"none"}' \
                "$user" "$DOMAIN" "$SECRET" "$PATHW" "$DOMAIN")
            LINK_TLS="vmess://$(printf '%s' "$j1" | base64 -w 0)"
            LINK_NTLS="vmess://$(printf '%s' "$j2" | base64 -w 0)" ;;
        vless)
            LINK_TLS="vless://${SECRET}@${DOMAIN}:443?path=${PATHENC}&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}"
            LINK_NTLS="vless://${SECRET}@${DOMAIN}:80?path=${PATHENC}&security=none&encryption=none&host=${DOMAIN}&type=ws#${user}" ;;
        trojan)
            LINK_TLS="trojan://${SECRET}@${DOMAIN}:443?path=${PATHENC}&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}"
            LINK_NTLS="" ;;
    esac
}

quota_label() {
    if [[ "$1" == "0" ]]; then printf 'Unlimited'; else printf '%s GB' "$1"; fi
}

iplimit_label() {
    if [[ -z "$1" || "$1" == "0" ]]; then printf 'Unlimited'; else printf '%s IP' "$1"; fi
}

con() {
    local -i bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(( (bytes + 1023)/1024 ))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(( (bytes + 1048575)/1048576 ))MB"
    else
        echo "$(( (bytes + 1073741823)/1073741824 ))GB"
    fi
}

ensure_cron() {
    mkdir -p "$STATE_DIR"
    touch "$TRIAL_LIST" "$IPLIMIT_DB" "$STRIKES_FILE" "$AUTOLOCK_FILE" "$SSH_LIMIT_DB" "$SSH_STRIKES" "$SSH_AUTOLOCK"
    chmod 600 "$TRIAL_LIST" "$IPLIMIT_DB" "$STRIKES_FILE" "$AUTOLOCK_FILE" "$SSH_LIMIT_DB" "$SSH_STRIKES" "$SSH_AUTOLOCK"
    if ! grep -q 'iplimit' "$CRON_FILE" 2>/dev/null; then
        {
            printf '* * * * * root /usr/local/bin/mzb-tools cleanup >/dev/null 2>&1\n'
            printf '* * * * * root /usr/local/bin/mzb-tools iplimit >/dev/null 2>&1\n'
        } > "$CRON_FILE"
        chmod 644 "$CRON_FILE"
    fi
    rm -f /etc/cron.d/mzb-trial
    if ! systemctl is-active --quiet cron 2>/dev/null; then
        systemctl enable --now cron >/dev/null 2>&1 || \
            print_warning "Layanan cron tidak aktif, pasang dengan: apt-get install -y cron"
    fi
}

tg_send() {
    local r
    r=$(curl -s -m 10 "${TG_API}/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHATID}" \
        --data-urlencode "parse_mode=HTML" \
        --data-urlencode "disable_web_page_preview=1" \
        --data-urlencode "text=$1")
    [[ "$r" == *'"ok":true'* ]]
}

notify_event() {
    [[ -n "$TG_TOKEN" && -n "$TG_CHATID" ]] || return 0
    local text
    text=$(printf '<b>┌───────────────────┐</b>\n<code>    NOTIF %s AKUN</code>\n<b>└───────────────────┘</b>\n<code> DOMAIN  : %s </code>\n<code> DATE    : %s </code>\n<code> DETAIL  : %s </code>\n<code> USER    : %s </code>\n<code> INFO    : %s </code>\n<b>└───────────────────┘</b>\n' \
        "$1" "${DOMAIN:0:5}xxx" "$(date '+%Y-%m-%d %H:%M:%S')" "${3:-?}" "$2" "$4")
    tg_send "$text" || true
}

autolock_del() {
    [[ -f "$AUTOLOCK_FILE" ]] && sed -i "/^$1|/d" "$AUTOLOCK_FILE"
    return 0
}

iplimit_get() {
    local v
    v=$(grep -m1 "^$1|" "$IPLIMIT_DB" 2>/dev/null | cut -d'|' -f2)
    printf '%s' "${v:-0}"
}

strike_clear() {
    [[ -f "$STRIKES_FILE" ]] && sed -i "/^$1|/d" "$STRIKES_FILE"
    return 0
}

iplimit_set() {
    mkdir -p "$STATE_DIR"
    touch "$IPLIMIT_DB"
    chmod 600 "$IPLIMIT_DB"
    sed -i "/^$1|/d" "$IPLIMIT_DB"
    if [[ "$2" =~ ^[0-9]+$ && "$2" -gt 0 ]]; then
        printf '%s|%s\n' "$1" "$2" >> "$IPLIMIT_DB"
        ensure_cron
    else
        strike_clear "$1"
    fi
}

iplimit_del() {
    [[ -f "$IPLIMIT_DB" ]] && sed -i "/^$1|/d" "$IPLIMIT_DB"
    strike_clear "$1"
    autolock_del "$1"
    return 0
}

process_autounlock() {
    [[ "$AUTO_UNLOCK" == "on" && -s "$AUTOLOCK_FILE" ]] || return 0
    local now keep u ts st protos
    now=$(date +%s)
    awk -F'|' -v n="$now" '$2<=n{f=1} END{exit !f}' "$AUTOLOCK_FILE" || return 0
    [[ -n "$TOKEN" ]] || login
    keep=$(mktemp)
    while IFS='|' read -r u ts; do
        [[ -z "$u" ]] && continue
        if (( ts > now )); then
            printf '%s|%s\n' "$u" "$ts" >> "$keep"
            continue
        fi
        api GET "/api/user/$u"
        if [[ "$CODE" == "200" ]]; then
            st=$(printf '%s' "$BODY" | pj 'd.get("status")')
            if [[ "$st" == "disabled" ]]; then
                api PUT "/api/user/$u" '{"status":"active"}'
                if [[ "$CODE" == "200" ]]; then
                    strike_clear "$u"
                    protos=$(printf '%s' "$BODY" | pj '",".join(d.get("proxies",{}).keys()).upper()')
                    printf '%s UNLOCK %s (otomatis)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" >> "$IPLIMIT_LOG"
                    notify_event UNLOCK "$u" "$protos" "Buka otomatis setelah ${AUTO_UNLOCK_MINUTES} menit"
                else
                    printf '%s|%s\n' "$u" "$ts" >> "$keep"      # coba lagi nanti
                fi
            fi
        elif [[ "$CODE" != "404" ]]; then
            printf '%s|%s\n' "$u" "$ts" >> "$keep"              # coba lagi nanti
        fi
    done < "$AUTOLOCK_FILE"
    cat "$keep" > "$AUTOLOCK_FILE"
    rm -f "$keep"
}

cmd_iplimit() {
    TOKEN=""
    ssh_process_autounlock
    ssh_limit_check
    process_autounlock
    [[ -s "$IPLIMIT_DB" && -f "$ACCESS_LOG" ]] || exit 0
    local result u n lim ips now protos info
    result=$(python3 - "$ACCESS_LOG" "$IP_WINDOW" "$IPLIMIT_DB" "$STRIKES_FILE" "$IPLIMIT_STRIKES" <<'PY'
import sys, re, os, time, datetime, ipaddress

log_file, win, db_file, strike_file, need = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], int(sys.argv[5])
UTC = datetime.timezone.utc
now = time.time()


def valid_ip(v):
    try:
        ipaddress.ip_address(v)
        return True
    except ValueError:
        return False


def clean_ip(v):
    ip = v.rsplit(":", 1)[0].strip("[]")
    return ip[7:] if ip.startswith("::ffff:") else ip


limits = {}
for ln in open(db_file):
    p = ln.strip().split("|")
    if len(p) == 2 and p[1].isdigit():
        limits[p[0]] = int(p[1])

strikes = {}
if os.path.isfile(strike_file):
    for ln in open(strike_file):
        p = ln.strip().split("|")
        if len(p) == 2 and p[1].isdigit():
            strikes[p[0]] = int(p[1])

seen = {}
size = os.path.getsize(log_file)
with open(log_file, "rb") as f:
    f.seek(max(0, size - 4 * 1024 * 1024))
    data = f.read().decode("utf-8", "ignore")
rx = re.compile(r"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})\S* from (?:\w+:)?(\S+) accepted .*email: \d+\.(\w+)\W*$")
for ln in data.splitlines():
    m = rx.match(ln)
    if not m:
        continue
    ts = datetime.datetime.strptime(m.group(1), "%Y/%m/%d %H:%M:%S").replace(tzinfo=UTC).timestamp()
    if now - ts > win:
        continue
    ip = clean_ip(m.group(2))
    if not valid_ip(ip):
        continue      # abaikan sumber bukan IP (mis. alamat socket lokal)
    seen.setdefault(m.group(3), set()).add(ip)

new = {}
for user, lim in limits.items():
    ips = sorted(seen.get(user, set()))
    if lim > 0 and len(ips) > lim:
        c = strikes.get(user, 0) + 1
        if c >= need:
            print("%s|%d|%d|%s" % (user, len(ips), lim, ",".join(ips)))
        else:
            new[user] = c

with open(strike_file, "w") as f:
    for u, c in new.items():
        f.write("%s|%d\n" % (u, c))
PY
)
    [[ -n "$result" ]] || exit 0

    [[ -n "$TOKEN" ]] || login
    now=$(date +%s)
    while IFS='|' read -r u n lim ips; do
        [[ -z "$u" ]] && continue
        api GET "/api/user/$u"
        if [[ "$CODE" == "404" ]]; then
            iplimit_del "$u"
            continue
        elif [[ "$CODE" != "200" || "$(printf '%s' "$BODY" | pj 'd.get("status")')" != "active" ]]; then
            continue
        fi
        api PUT "/api/user/$u" '{"status":"disabled"}'
        if [[ "$CODE" == "200" ]]; then
            protos=$(printf '%s' "$BODY" | pj '",".join(d.get("proxies",{}).keys()).upper()')
            printf '%s LOCK %s ip=%s limit=%s [%s]\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" "$n" "$lim" "$ips" >> "$IPLIMIT_LOG"
            info="Limit IP $n/$lim"
            if [[ "$AUTO_UNLOCK" == "on" ]]; then
                autolock_del "$u"
                printf '%s|%s\n' "$u" $(( now + AUTO_UNLOCK_MINUTES * 60 )) >> "$AUTOLOCK_FILE"
                info="$info, buka otomatis ${AUTO_UNLOCK_MINUTES} menit"
            fi
            notify_event LOCK "$u" "$protos" "$info"
        elif [[ "$CODE" == "404" ]]; then
            iplimit_del "$u"
        fi
    done <<< "$result"
}

create_account() {
    local u="$1" ex="$2" gb="$3" exp_label="$4" ipl="${5:-0}" dl payload
    dl=$(( gb * 1024 * 1024 * 1024 ))
    payload=$(printf '{"username":"%s","proxies":{"%s":{}},"inbounds":{"%s":[%s]},"expire":%s,"data_limit":%s,"status":"active"}' \
        "$u" "$PROTO" "$PROTO" "$TAGS" "$ex" "$dl")
    api POST /api/user "$payload"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        api_error "Gagal membuat akun"
        echo ""
        exit 1
    fi

    user="$u"
    IPLIM="$ipl"
    iplimit_set "$u" "$ipl"
    if [[ "$PROTO" == "trojan" ]]; then
        SECRET=$(printf '%s' "$BODY" | pj 'd["proxies"]["trojan"]["password"]')
        SECRET_LABEL="Password"
    else
        SECRET=$(printf '%s' "$BODY" | pj 'd["proxies"][P]["id"]')
        SECRET_LABEL="UUID"
    fi
    SUB_URL=$(printf '%s' "$BODY" | pj 'd.get("subscription_url") or ""')
    build_links
    show_account "$gb" "$exp_label"
    if [[ "$ipl" != "0" && ! -f "$ACCESS_LOG" ]]; then
        print_warning "Access log belum aktif, limit IP belum bisa berjalan"
        echo ""
    fi
}

show_account() {
    # tampilkan hanya subscription URL (berisi semua varian TLS & NoTLS)
    box_kv "User" "$user"
    box_kv "Protokol" "$TITLE"
    box_kv "Quota" "$(quota_label "$gb")"
    box_kv "Limit IP" "$(iplimit_label "$IPLIM")"
    box_kv "Expired Akun" "$exp_label"
    box_mid
    box_text "Subscription (semua TLS & NoTLS) :"
    box_link "$SUB_URL"
    box_bottom
    echo ""
}
valid_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_]{3,32}$ ]]
}

ask_number() {
    local __v="" __min="${3:-0}"
    until [[ "$__v" =~ ^[0-9]+$ && "$__v" -ge "$__min" ]]; do
        read -rp "$(prompt_str "$2")" __v
        [[ "$__v" =~ ^[0-9]+$ && "$__v" -ge "$__min" ]] || print_error "Harus angka (minimal $__min)"
    done
    printf -v "$1" '%s' "$__v"
}

cmd_add() {
    local masaaktif Quota iplimit exp_ts
    clear
    box_header "ADD $TITLE ACCOUNT"
    echo ""

    read -rp "$(prompt_str "Input Username")" -e user
    if ! valid_username "$user"; then
        echo ""
        print_error "Username 3-32 karakter, hanya huruf, angka, dan underscore"
        echo ""
        exit 1
    fi
    api GET "/api/user/$user"
    if [[ "$CODE" == "200" ]]; then
        echo ""
        print_error "Username '$user' sudah ada. Coba username lain"
        echo ""
        exit 1
    fi

    ask_number masaaktif "Expired (days)" 1
    ask_number Quota "Limit User (GB, 0 = unlimited)"
    ask_number iplimit "Limit User (IP, 0 = unlimited)"

    exp_ts=$(( $(date +%s) + masaaktif * 86400 ))
    create_account "$user" "$exp_ts" "$Quota" "$(date -d "@$exp_ts" +%Y-%m-%d)" "$iplimit"
}

cmd_trial() {
    local menit exp_ts
    clear
    box_header "TRIAL $TITLE ACCOUNT"
    echo ""

    while :; do
        user="trial$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
        api GET "/api/user/$user"
        [[ "$CODE" == "200" ]] || break
    done

    ask_number menit "Expired (menit)" 1

    exp_ts=$(( $(date +%s) + menit * 60 ))
    create_account "$user" "$exp_ts" "$TRIAL_GB" \
        "$(date -d "@$exp_ts" '+%Y-%m-%d %H:%M') (Trial ${menit} menit)" "$TRIAL_IP"

    ensure_cron
    printf '%s|%s|%s\n' "$user" "$PROTO" "$exp_ts" >> "$TRIAL_LIST"
    print_info "Akun ini dihapus otomatis setelah $menit menit"
    echo ""
}

xray_delete_expired() {
    if [[ -z "$TOKEN" ]]; then
        login_quiet || return 0
    fi
    api GET "/api/users?limit=1000"
    [[ "$CODE" == "200" ]] || return 0
    local now u list
    now=$(date +%s)
    list=$(printf '%s' "$BODY" | python3 -c '
import sys, json
now = int(sys.argv[1])
for u in json.load(sys.stdin).get("users", []):
    e = u.get("expire")
    if e and e > 0 and e <= now:
        print(u["username"])
' "$now" 2>/dev/null)
    for u in $list; do
        if api_delete_user "$u"; then
            iplimit_del "$u"
            printf '%s DELETE xray:%s (expired)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" >> "$IPLIMIT_LOG"
        fi
    done
    return 0
}

cmd_cleanup() {
    ssh_enforce_expiry
    xray_delete_expired
    [[ -s "$TRIAL_LIST" ]] || exit 0
    local now keep u pr ex cur
    now=$(date +%s)
    keep=$(mktemp)
    while IFS='|' read -r u pr ex; do
        [[ -z "$u" ]] && continue
        if (( ex > now )); then
            printf '%s|%s|%s\n' "$u" "$pr" "$ex" >> "$keep"
            continue
        fi
        if [[ "$pr" == "ssh" ]]; then
            ssh_kill_sessions "$u"
            userdel -f "$u" >/dev/null 2>&1
            ssh_limit_del "$u"
            continue
        fi
        if [[ -z "$TOKEN" ]] && ! login_quiet; then
            printf '%s|%s|%s\n' "$u" "$pr" "$ex" >> "$keep"
            continue
        fi
        api GET "/api/user/$u"
        if [[ "$CODE" == "404" ]]; then
            iplimit_del "$u"              # sudah tidak ada
        elif [[ "$CODE" == "200" ]]; then
            cur=$(printf '%s' "$BODY" | pj 'd.get("expire") or 0')
            if (( cur > ex + 60 )); then
                continue                  # sudah diperpanjang, jangan dihapus
            fi
            if api_delete_user "$u"; then
                iplimit_del "$u"
            else
                printf '%s|%s|%s\n' "$u" "$pr" "$ex" >> "$keep"   # coba lagi nanti
            fi
        else
            printf '%s|%s|%s\n' "$u" "$pr" "$ex" >> "$keep"
        fi
    done < "$TRIAL_LIST"
    cat "$keep" > "$TRIAL_LIST"
    rm -f "$keep"
}

USERS_LIST=""
list_users() {
    local flt="${1:-}" emptymsg="${2:-Belum ada akun $TITLE}"
    api GET "/api/users?limit=1000"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        api_error "Gagal mengambil daftar akun"
        echo ""
        return 1
    fi
    USERS_LIST=$(printf '%s' "$BODY" | python3 -c '
import sys, json, datetime
p, flt = sys.argv[1], sys.argv[2]
d = json.load(sys.stdin)
for u in d.get("users", []):
    if p not in (u.get("proxies") or {}):
        continue
    if flt and u.get("status") != flt:
        continue
    e = u.get("expire")
    es = datetime.datetime.fromtimestamp(e).strftime("%Y-%m-%d") if e else "Unlimited"
    print("%s|%s|%s" % (u["username"], es, u.get("status", "")))
' "$PROTO" "$flt")
    if [[ -z "$USERS_LIST" ]]; then
        echo ""
        print_warning "$emptymsg"
        echo ""
        return 1
    fi
}

show_users() {
    local n=0 name exp st
    box_top
    box_table_head "No" "Username" "Expired"
    box_mid
    while IFS='|' read -r name exp st; do
        n=$((n + 1))
        if [[ "$st" == "active" ]]; then st=""; fi
        box_table_row "$n" "$name" "$exp" "$st"
    done <<< "$USERS_LIST"
    box_bottom
    echo ""
}

pick_user() {
    local input
    read -rp "$(prompt_str "Input Username / No")" -e input
    user=""
    [[ -z "$input" ]] && return 2
    if printf '%s\n' "$USERS_LIST" | cut -d'|' -f1 | grep -qx -- "$input"; then
        user="$input"
    elif [[ "$input" =~ ^[0-9]+$ ]]; then
        user=$(printf '%s\n' "$USERS_LIST" | sed -n "${input}p" | cut -d'|' -f1)
    fi
    if [[ -z "$user" ]]; then
        echo ""
        print_error "Akun $TITLE '$input' tidak ditemukan"
        echo ""
        return 1
    fi
    return 0
}

cmd_renew() {
    local masaaktif Quota iplimit cur_exp now base new_exp dl
    clear
    box_header "RENEW $TITLE ACCOUNT"
    echo ""
    list_users || exit 0
    show_users
    pick_user || exit 0

    api GET "/api/user/$user"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        api_error "Gagal membaca akun"
        echo ""
        exit 1
    fi
    cur_exp=$(printf '%s' "$BODY" | pj 'd.get("expire") or 0')

    ask_number masaaktif "Tambah Expired (days)" 1
    ask_number Quota "Limit User (GB, 0 = unlimited)"
    ask_number iplimit "Limit User (IP, 0 = unlimited)"

    now=$(date +%s)
    base=$(( cur_exp > now ? cur_exp : now ))
    new_exp=$(( base + masaaktif * 86400 ))
    dl=$(( Quota * 1024 * 1024 * 1024 ))

    api PUT "/api/user/$user" "$(printf '{"expire":%s,"data_limit":%s,"status":"active"}' "$new_exp" "$dl")"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        api_error "Gagal memperpanjang akun"
        echo ""
        exit 1
    fi
    api POST "/api/user/$user/reset"
    iplimit_set "$user" "$iplimit"
    strike_clear "$user"

    clear
    box_header "RENEW $TITLE ACCOUNT"
    box_top
    box_kv "User" "$user"
    box_kv "Quota" "$(quota_label "$Quota")"
    box_kv "Limit IP" "$(iplimit_label "$iplimit")"
    box_kv "Tambah" "$masaaktif hari"
    box_kv "Expired Akun" "$(date -d "@$new_exp" +%Y-%m-%d)"
    box_bottom
    echo ""
    print_success "Akun $user berhasil diperpanjang"
    echo ""
}

cmd_dell() {
    local yn
    clear
    box_header "DELETE $TITLE ACCOUNT"
    echo ""
    list_users || exit 0
    show_users
    pick_user || exit 0

    read -rp "$(prompt_str "Hapus akun '$user'? (y/N)")" yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then
        echo ""
        print_warning "Dibatalkan"
        echo ""
        exit 0
    fi

    echo ""
    if api_delete_user "$user"; then
        iplimit_del "$user"
        print_success "Akun $user berhasil dihapus"
        if [[ -n "$DEL_NOTE" ]]; then
            print_warning "$DEL_NOTE"
            print_warning "Akun masih bisa aktif di Xray sampai Marzban di-restart: marzban restart"
        fi
    else
        api_error "Gagal menghapus akun"
        marzban_log_hint
        echo ""
        exit 1
    fi
    echo ""
}

cmd_lockunlock() {
    local mode="$1" flt newst word exp
    if [[ "$mode" == "lock" ]]; then
        flt="active";   newst="disabled"; word="Locked"
    else
        flt="disabled"; newst="active";   word="Unlocked"
    fi
    clear
    box_header "$(printf '%s' "${mode^^}") $TITLE ACCOUNT"
    echo ""
    if [[ "$mode" == "lock" ]]; then
        list_users "$flt" "Tidak ada akun $TITLE yang bisa dikunci" || return 0
    else
        list_users "$flt" "Tidak ada akun $TITLE yang sedang dikunci" || return 0
    fi
    show_users
    print_warning "Tip: kosongkan input untuk kembali"
    pick_user || return 0
    exp=$(printf '%s\n' "$USERS_LIST" | awk -F'|' -v u="$user" '$1==u{print $2; exit}')

    api PUT "/api/user/$user" "$(printf '{"status":"%s"}' "$newst")"
    if [[ "$CODE" != "200" ]]; then
        echo ""
        api_error "Gagal mengubah status akun"
        echo ""
        return 0
    fi
    [[ "$mode" == "unlock" ]] && strike_clear "$user"
    autolock_del "$user"      # kunci/buka manual menggantikan jadwal buka otomatis

    clear
    box_header "$(printf '%s' "${mode^^}") $TITLE ACCOUNT"
    echo ""
    box_top
    box_kv "Username Info" "$user"
    box_kv "Expired Account" "$exp"
    box_kv "Status $word" "Success"
    box_kv "Message" "Terima kasih telah menggunakan layanan kami"
    box_bottom
    echo ""
    notify_event "${mode^^}" "$user" "$TITLE" "Manual (admin)"
}

cmd_setbot() {
    local opt tok chat
    while :; do
        clear
        box_header "SETTING BOT NOTIFIKASI"
        box_top
        if [[ -n "$TG_TOKEN" && -n "$TG_CHATID" ]]; then
            box_kv "Status" "Aktif"
            box_kv "Token" "${TG_TOKEN:0:6}...${TG_TOKEN: -4}"
            box_kv "Chat ID" "$TG_CHATID"
        else
            box_kv "Status" "Belum diatur"
        fi
        box_bottom
        box_top2
        box_menu2 "1" "Set Token & Chat ID" "3" "Hapus Bot"
        box_menu2 "2" "Kirim Pesan Tes" "0" "Kembali"
        box_bottom2
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1)
                echo ""
                read -rp "$(prompt_str "Token Bot (dari @BotFather)")" tok
                if [[ ! "$tok" =~ ^[0-9]+:[A-Za-z0-9_-]{20,}$ ]]; then
                    print_error "Format token tidak valid"
                    ui_pause "Press any key to continue"
                    continue
                fi
                read -rp "$(prompt_str "Chat ID")" chat
                if [[ ! "$chat" =~ ^-?[0-9]+$ ]]; then
                    print_error "Chat ID harus angka (boleh diawali tanda minus untuk grup)"
                    ui_pause "Press any key to continue"
                    continue
                fi
                conf_set TG_TOKEN "$tok"
                conf_set TG_CHATID "$chat"
                echo ""
                if tg_send "<b>Notifikasi lock/unlock akun aktif</b>"; then
                    print_success "Tersimpan, pesan tes terkirim"
                else
                    print_warning "Tersimpan, tetapi pesan tes gagal. Cek token dan chat ID, dan pastikan sudah menekan Start pada bot"
                fi
                ui_pause "Press any key to continue" ;;
            2)
                echo ""
                if [[ -z "$TG_TOKEN" || -z "$TG_CHATID" ]]; then
                    print_error "Bot belum diatur"
                elif tg_send "<b>Tes notifikasi Marzban Tools</b>"; then
                    print_success "Pesan tes terkirim"
                else
                    print_error "Pesan tes gagal terkirim. Cek token, chat ID, dan koneksi server"
                fi
                ui_pause "Press any key to continue" ;;
            3)
                conf_set TG_TOKEN ""
                conf_set TG_CHATID ""
                echo ""
                print_success "Bot dihapus, notifikasi dimatikan"
                ui_pause "Press any key to continue" ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1 ;;
        esac
    done
}

cmd_setunlock() {
    local opt mins
    while :; do
        clear
        box_header "SETTING AUTO UNLOCK"
        box_top
        if [[ "$AUTO_UNLOCK" == "on" ]]; then
            box_kv "Auto Unlock" "ON"
        else
            box_kv "Auto Unlock" "OFF"
        fi
        box_kv "Durasi Lock" "${AUTO_UNLOCK_MINUTES} menit"
        box_text "Berlaku untuk akun yang dikunci oleh limit IP."
        box_text "Kunci manual tetap sampai Anda membukanya."
        box_bottom
        box_top2
        box_menu2 "1" "Auto Unlock ON/OFF" "2" "Atur Durasi Lock"
        box_bottom2
        box_top
        box_center "Press [0] to go back"
        box_bottom
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1)
                echo ""
                if [[ "$AUTO_UNLOCK" == "on" ]]; then
                    conf_set AUTO_UNLOCK "off"
                    : > "$AUTOLOCK_FILE"
                    print_success "Auto unlock dimatikan, akun terkunci tetap sampai dibuka manual"
                else
                    conf_set AUTO_UNLOCK "on"
                    print_success "Auto unlock dinyalakan untuk akun yang dikunci mulai sekarang"
                fi
                ui_pause "Press any key to continue" ;;
            2)
                echo ""
                ask_number mins "Durasi Lock (menit, minimal 3)" 3
                conf_set AUTO_UNLOCK_MINUTES "$mins"
                print_success "Durasi lock diatur ke $mins menit"
                ui_pause "Press any key to continue" ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1 ;;
        esac
    done
}

cmd_menulock() {
    local opt
    while :; do
        clear
        box_header "MENU LOCK/UNLOCK"
        box_top2
        box_menu2 "1" "Lock Vmess Account" "4" "Unlock Vmess Account"
        box_menu2 "2" "Lock Vless Account" "5" "Unlock Vless Account"
        box_menu2 "3" "Lock Trojan Account" "6" "Unlock Trojan Account"
        box_menu2 "7" "Setting Bot Notif" "8" "Setting Auto Unlock"
        box_bottom2
        box_top
        box_center "Press [0] or [x] to exit"
        box_bottom
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1) set_proto ws; cmd_lockunlock lock ;;
            2) set_proto vl; cmd_lockunlock lock ;;
            3) set_proto tr; cmd_lockunlock lock ;;
            4) set_proto ws; cmd_lockunlock unlock ;;
            5) set_proto vl; cmd_lockunlock unlock ;;
            6) set_proto tr; cmd_lockunlock unlock ;;
            7) cmd_setbot; continue ;;
            8) cmd_setunlock; continue ;;
            0|x|X) clear; exit 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1; continue ;;
        esac
        ui_pause "Press any key to continue"
    done
}

cmd_cek() {
    local tmp total=0 name last used lim ips n result
    clear
    box_header "CHECK ONLINE $TITLE"
    echo ""

    api GET "/api/users?limit=1000"
    if [[ "$CODE" != "200" ]]; then
        api_error "Gagal mengambil daftar akun"
        echo ""
        exit 1
    fi
    if [[ ! -f "$ACCESS_LOG" ]]; then
        print_warning "Access log belum aktif, IP login tidak bisa ditampilkan"
        echo ""
    fi

    tmp=$(mktemp)
    printf '%s' "$BODY" > "$tmp"
    result=$(python3 - "$PROTO" "$ONLINE_WINDOW" "$tmp" "$ACCESS_LOG" "$IP_WINDOW" <<'PY'
import sys, json, os, re, datetime, time, ipaddress

proto, win, body_file, log_file = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
ip_win = int(sys.argv[5])
UTC = datetime.timezone.utc
now = time.time()
d = json.load(open(body_file))


def valid_ip(v):
    try:
        ipaddress.ip_address(v)
        return True
    except ValueError:
        return False


def clean_ip(v):
    ip = v.rsplit(":", 1)[0].strip("[]")
    return ip[7:] if ip.startswith("::ffff:") else ip


def online_ts(s):
    if not s:
        return None
    try:
        dt = datetime.datetime.fromisoformat(s.replace("Z", ""))
        return dt.replace(tzinfo=UTC).timestamp()
    except Exception:
        return None


have_log = os.path.isfile(log_file)
seen = {}
if have_log:
    size = os.path.getsize(log_file)
    with open(log_file, "rb") as f:
        f.seek(max(0, size - 4 * 1024 * 1024))
        data = f.read().decode("utf-8", "ignore")
    rx = re.compile(r"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})\S* from (?:\w+:)?(\S+) accepted .*email: \d+\.(\w+)\W*$")
    for ln in data.splitlines():
        m = rx.match(ln)
        if not m:
            continue
        ts = datetime.datetime.strptime(m.group(1), "%Y/%m/%d %H:%M:%S").replace(tzinfo=UTC).timestamp()
        if now - ts > ip_win:
            continue
        ip = clean_ip(m.group(2))
        if not valid_ip(ip):
            continue      # abaikan sumber bukan IP (mis. alamat socket lokal)
        seen.setdefault(m.group(3), set()).add(ip)

for u in d.get("users", []):
    if proto not in (u.get("proxies") or {}):
        continue
    name = u["username"]
    ts = online_ts(u.get("online_at"))
    recent = ts is not None and now - ts <= win
    ips = sorted(seen.get(name, set())) if have_log else []
    if not (recent or ips):
        continue
    last = datetime.datetime.fromtimestamp(ts).strftime("%H:%M:%S") if ts else "N/A"
    print("|".join([name, last, str(u.get("used_traffic") or 0), str(u.get("data_limit") or 0),
                    ", ".join(ips) if have_log else "-"]))
PY
)
    rm -f "$tmp"

    while IFS='|' read -r name last used lim ips; do
        [[ -z "$name" ]] && continue
        n=0
        [[ "$ips" != "-" && -n "$ips" ]] && n=$(printf '%s' "$ips" | awk -F', ' '{print NF}')
        [[ "$ips" == "-" ]] && n="-"
        [[ -z "$ips" ]] && ips="-"
        box_top
        box_kv "Username" "$name"
        box_kv "Last Login" "$last"
        box_kv "Usage Quota" "$(con "$used")"
        if [[ "$lim" == "0" ]]; then
            box_kv "Limit Quota" "Unlimited"
        else
            box_kv "Limit Quota" "$(con "$lim")"
        fi
        box_kv "Limit IP" "$(iplimit_label "$(iplimit_get "$name")")"
        box_kv "User Login" "$n"
        box_kv "IP Login" "$ips"
        box_bottom
        echo ""
        total=$((total + 1))
    done <<< "$result"

    if [[ $total -eq 0 ]]; then
        print_error "No users currently online"
    else
        box_top
        box_center "Total User Online :${GREEN} $total"
        box_bottom
    fi
    echo ""
}

ssh_users() {
    awk -F: '$3>=1000 && $3<65534 && $7=="/bin/false"{print $1}' /etc/passwd | sort
}

ssh_today() { echo $(( $(date -u +%s) / 86400 )); }

ssh_exp_day() {
    local d
    d=$(getent shadow "$1" | cut -d: -f8)
    [[ "$d" =~ ^[0-9]+$ ]] && echo "$d" || echo 0
}

ssh_day_label() {
    if [[ "$1" -gt 0 ]]; then date -u -d "@$(( $1 * 86400 ))" +%Y-%m-%d; else printf 'Unlimited'; fi
}

ssh_status() {
    local e st
    e=$(ssh_exp_day "$1")
    if (( e > 0 && $(ssh_today) >= e )); then echo "expired"; return; fi
    st=$(passwd -S "$1" 2>/dev/null | awk '{print $2}')
    if [[ "$st" == "L" ]]; then echo "locked"; else echo "active"; fi
}

ssh_sessions() {
    journalctl -u dropbear-ws -o short --no-pager --since "-3 days" 2>/dev/null | python3 -c '
import sys, re, os
rx_ok = re.compile(r"^\w{3} +\d+ (\d{2}:\d{2}:\d{2}) \S+ dropbear\[(\d+)\]: .*?(?:Password|Pubkey) auth succeeded for \x27([^\x27]+)\x27")
rx_exit = re.compile(r"dropbear\[(\d+)\]: .*?\bExit\b")
live = {}
for ln in sys.stdin:
    m = rx_ok.match(ln)
    if m:
        live[m.group(2)] = (m.group(3), m.group(1))
        continue
    m = rx_exit.search(ln)
    if m:
        live.pop(m.group(1), None)
for pid, (user, t) in live.items():
    try:
        if open("/proc/%s/comm" % pid).read().strip() != "dropbear":
            continue
        os.kill(int(pid), 0)
    except Exception:
        continue
    print("%s|%s|%s" % (user, pid, t))
'
}

ssh_kill_sessions() {
    local pid
    for pid in $(ssh_sessions | awk -F'|' -v u="$1" '$1==u{print $2}'); do
        kill "$pid" 2>/dev/null
    done
    return 0
}

ssh_limit_get() {
    local v
    v=$(grep -m1 "^$1|" "$SSH_LIMIT_DB" 2>/dev/null | cut -d'|' -f2)
    printf '%s' "${v:-0}"
}

ssh_limit_label() {
    if [[ -z "$1" || "$1" == "0" ]]; then printf 'Unlimited'; else printf '%s Login' "$1"; fi
}

ssh_limit_set() {
    mkdir -p "$STATE_DIR"
    touch "$SSH_LIMIT_DB"
    chmod 600 "$SSH_LIMIT_DB"
    sed -i "/^$1|/d" "$SSH_LIMIT_DB"
    if [[ "$2" =~ ^[0-9]+$ && "$2" -gt 0 ]]; then
        printf '%s|%s\n' "$1" "$2" >> "$SSH_LIMIT_DB"
        ensure_cron
    else
        sed -i "/^$1|/d" "$SSH_STRIKES" 2>/dev/null
    fi
    return 0
}

ssh_limit_del() {
    local f
    for f in "$SSH_LIMIT_DB" "$SSH_STRIKES" "$SSH_AUTOLOCK"; do
        [[ -f "$f" ]] && sed -i "/^$1|/d" "$f"
    done
    return 0
}

ssh_login_counts() {
    ssh_sessions | awk -F'|' '{c[$1]++; if ($3 > t[$1]) t[$1]=$3} END{for (u in c) print u"|"c[u]"|"t[u]}' | sort
}

ssh_limit_check() {
    [[ -s "$SSH_LIMIT_DB" ]] || return 0
    local counts u lim n c now
    counts=$(ssh_login_counts)
    [[ -n "$counts" ]] || { : > "$SSH_STRIKES"; return 0; }
    now=$(date +%s)
    while IFS='|' read -r u lim; do
        [[ -z "$u" ]] && continue
        if ! id "$u" >/dev/null 2>&1; then
            ssh_limit_del "$u"
            continue
        fi
        n=$(printf '%s\n' "$counts" | awk -F'|' -v u="$u" '$1==u{print $2; exit}')
        n=${n:-0}
        if (( lim > 0 && n > lim )) && [[ "$(ssh_status "$u")" == "active" ]]; then
            c=$(( $(grep -m1 "^$u|" "$SSH_STRIKES" 2>/dev/null | cut -d'|' -f2) + 1 ))
            if (( c >= IPLIMIT_STRIKES )); then
                sed -i "/^$u|/d" "$SSH_STRIKES"
                passwd -l "$u" >/dev/null 2>&1
                ssh_kill_sessions "$u"
                printf '%s LOCK ssh:%s login=%s limit=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" "$n" "$lim" >> "$IPLIMIT_LOG"
                info="Limit Login $n/$lim"
                if [[ "$AUTO_UNLOCK" == "on" ]]; then
                    sed -i "/^$u|/d" "$SSH_AUTOLOCK"
                    printf '%s|%s\n' "$u" $(( now + AUTO_UNLOCK_MINUTES * 60 )) >> "$SSH_AUTOLOCK"
                    info="$info, buka otomatis ${AUTO_UNLOCK_MINUTES} menit"
                fi
                notify_event LOCK "$u" "SSH" "$info"
            else
                sed -i "/^$u|/d" "$SSH_STRIKES"
                printf '%s|%s\n' "$u" "$c" >> "$SSH_STRIKES"
            fi
        else
            sed -i "/^$u|/d" "$SSH_STRIKES" 2>/dev/null
        fi
    done < "$SSH_LIMIT_DB"
    return 0
}

ssh_process_autounlock() {
    [[ "$AUTO_UNLOCK" == "on" && -s "$SSH_AUTOLOCK" ]] || return 0
    local now keep u ts
    now=$(date +%s)
    keep=$(mktemp)
    while IFS='|' read -r u ts; do
        [[ -z "$u" ]] && continue
        if (( ts > now )); then
            printf '%s|%s\n' "$u" "$ts" >> "$keep"
            continue
        fi
        if id "$u" >/dev/null 2>&1 && [[ "$(ssh_status "$u")" == "locked" ]]; then
            passwd -u "$u" >/dev/null 2>&1
            printf '%s UNLOCK ssh:%s (otomatis)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" >> "$IPLIMIT_LOG"
            notify_event UNLOCK "$u" "SSH" "Buka otomatis setelah ${AUTO_UNLOCK_MINUTES} menit"
        fi
    done < "$SSH_AUTOLOCK"
    cat "$keep" > "$SSH_AUTOLOCK"
    rm -f "$keep"
    return 0
}

ssh_enforce_expiry() {
    local u
    for u in $(ssh_users); do
        if [[ "$(ssh_status "$u")" == "expired" ]]; then
            passwd -l "$u" >/dev/null 2>&1
            ssh_kill_sessions "$u"
            if userdel -f "$u" >/dev/null 2>&1; then
                ssh_limit_del "$u"
                printf '%s DELETE ssh:%s (expired)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$u" >> "$IPLIMIT_LOG"
            fi
        fi
    done
    return 0
}

ssh_list_users() {
    local flt="${1:-}" emptymsg="${2:-Belum ada akun SSH}" u st
    USERS_LIST=""
    for u in $(ssh_users); do
        st=$(ssh_status "$u")
        [[ -n "$flt" && "$st" != "$flt" ]] && continue
        USERS_LIST+="$u|$(ssh_day_label "$(ssh_exp_day "$u")")|$st"$'\n'
    done
    USERS_LIST="${USERS_LIST%$'\n'}"
    if [[ -z "$USERS_LIST" ]]; then
        echo ""
        print_warning "$emptymsg"
        echo ""
        return 1
    fi
}

ssh_valid_user() {
    [[ "$1" =~ ^[a-z_][a-z0-9_-]{2,31}$ ]]
}

ssh_random() {
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$1"
}

ssh_show_account() {
    clear
    box_header "PREMIUM SSH ACCOUNT"
    box_top
    box_kv "Username" "$1"
    box_kv "Password" "$2"
    box_kv "Domain" "$DOMAIN"
    box_kv "Port TLS" "443"
    box_kv "Port NTLS" "80"
    box_kv "Path WS" "/"
    box_kv "UDPGW" "7300"
    box_kv "Limit Login" "$(ssh_limit_label "$SSH_LIM")"
    box_mid
    box_text "Payload WebSocket :"
    box_link "GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: websocket[crlf][crlf]"
    box_mid
    box_text "Format Akun TLS :"
    box_link "${DOMAIN}:443@$1:$2"
    box_mid
    box_text "Format Akun NTLS :"
    box_link "${DOMAIN}:80@$1:$2"
    box_mid
    box_kv "Expired Akun" "$3"
    box_bottom
    echo ""
}

ssh_create() {
    grep -qx '/bin/false' /etc/shells 2>/dev/null || echo '/bin/false' >> /etc/shells
    useradd -M -s /bin/false "$1" >/dev/null 2>&1 || return 1
    { echo "$1:$2" | chpasswd -c SHA512 2>/dev/null || echo "$1:$2" | chpasswd >/dev/null 2>&1; } \
        || { userdel -f "$1" >/dev/null 2>&1; return 1; }
    chage -E "$3" "$1" >/dev/null 2>&1
    return 0
}

cmd_ssh_add() {
    TITLE="SSH"
    local user pass days lim
    clear
    box_header "ADD SSH ACCOUNT"
    echo ""
    read -rp "$(prompt_str "Input Username")" -e user
    if ! ssh_valid_user "$user"; then
        echo ""
        print_error "Username 3-32 karakter: huruf kecil, angka, - dan _ (awal huruf)"
        echo ""
        exit 1
    fi
    if id "$user" >/dev/null 2>&1; then
        echo ""
        print_error "Username '$user' sudah ada. Coba username lain"
        echo ""
        exit 1
    fi
    read -rp "$(prompt_str "Input Password (kosong = acak)")" pass
    [[ -n "$pass" ]] || pass=$(ssh_random 8)
    ask_number days "Expired (days)" 1
    ask_number lim "Limit Login (0 = unlimited)"
    if ! ssh_create "$user" "$pass" $(( $(ssh_today) + days )); then
        echo ""
        print_error "Gagal membuat akun SSH"
        echo ""
        exit 1
    fi
    ssh_limit_set "$user" "$lim"
    SSH_LIM="$lim"
    ssh_show_account "$user" "$pass" "$(ssh_day_label $(( $(ssh_today) + days )))"
}

cmd_ssh_trial() {
    TITLE="SSH"
    local user pass menit exp_ts
    clear
    box_header "TRIAL SSH ACCOUNT"
    echo ""
    ask_number menit "Expired (menit)" 1
    while :; do
        user="trial$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
        id "$user" >/dev/null 2>&1 || break
    done
    pass=$(ssh_random 8)
    exp_ts=$(( $(date +%s) + menit * 60 ))
    if ! ssh_create "$user" "$pass" $(( $(ssh_today) + 2 )); then
        echo ""
        print_error "Gagal membuat akun SSH"
        echo ""
        exit 1
    fi
    ensure_cron
    printf '%s|ssh|%s\n' "$user" "$exp_ts" >> "$TRIAL_LIST"
    ssh_limit_set "$user" "$TRIAL_IP"
    SSH_LIM="$TRIAL_IP"
    ssh_show_account "$user" "$pass" "$(date -d "@$exp_ts" '+%Y-%m-%d %H:%M') (Trial ${menit} menit)"
    print_info "Akun ini dihapus otomatis setelah $menit menit"
    echo ""
}

cmd_ssh_renew() {
    TITLE="SSH"
    local days lim e now base new st
    clear
    box_header "RENEW SSH ACCOUNT"
    echo ""
    ssh_list_users || exit 0
    show_users
    pick_user || exit 0
    ask_number days "Tambah Expired (days)" 1
    ask_number lim "Limit Login (0 = unlimited)"
    e=$(ssh_exp_day "$user")
    st=$(ssh_status "$user")
    now=$(ssh_today)
    base=$(( e > now ? e : now ))
    new=$(( base + days ))
    chage -E "$new" "$user"
    [[ "$st" == "expired" ]] && passwd -u "$user" >/dev/null 2>&1
    ssh_limit_set "$user" "$lim"
    sed -i "/^$user|/d" "$SSH_STRIKES" 2>/dev/null
    clear
    box_header "RENEW SSH ACCOUNT"
    box_top
    box_kv "User" "$user"
    box_kv "Limit Login" "$(ssh_limit_label "$lim")"
    box_kv "Tambah" "$days hari"
    box_kv "Expired Akun" "$(ssh_day_label "$new")"
    box_bottom
    echo ""
    print_success "Akun $user berhasil diperpanjang"
    echo ""
}

cmd_ssh_dell() {
    TITLE="SSH"
    local yn
    clear
    box_header "DELETE SSH ACCOUNT"
    echo ""
    ssh_list_users || exit 0
    show_users
    pick_user || exit 0
    read -rp "$(prompt_str "Hapus akun '$user'? (y/N)")" yn
    if [[ ! "$yn" =~ ^[yY]$ ]]; then
        echo ""
        print_warning "Dibatalkan"
        echo ""
        exit 0
    fi
    ssh_kill_sessions "$user"
    ssh_limit_del "$user"
    echo ""
    if userdel -f "$user" >/dev/null 2>&1; then
        print_success "Akun $user berhasil dihapus"
    else
        print_error "Gagal menghapus akun $user"
        echo ""
        exit 1
    fi
    echo ""
}

cmd_ssh_lockunlock() {
    TITLE="SSH"
    local mode="$1" flt word exp
    if [[ "$mode" == "lock" ]]; then flt="active"; word="Locked"; else flt="locked"; word="Unlocked"; fi
    clear
    box_header "$(printf '%s' "${mode^^}") SSH ACCOUNT"
    echo ""
    if [[ "$mode" == "lock" ]]; then
        ssh_list_users "$flt" "Tidak ada akun SSH yang bisa dikunci" || return 0
    else
        ssh_list_users "$flt" "Tidak ada akun SSH yang sedang dikunci" || return 0
    fi
    show_users
    print_warning "Tip: kosongkan input untuk kembali"
    pick_user || return 0
    exp=$(printf '%s\n' "$USERS_LIST" | awk -F'|' -v u="$user" '$1==u{print $2; exit}')
    sed -i "/^$user|/d" "$SSH_AUTOLOCK" 2>/dev/null     # kunci/buka manual menggantikan jadwal otomatis
    sed -i "/^$user|/d" "$SSH_STRIKES" 2>/dev/null
    if [[ "$mode" == "lock" ]]; then
        passwd -l "$user" >/dev/null 2>&1
        ssh_kill_sessions "$user"
    else
        passwd -u "$user" >/dev/null 2>&1
    fi
    clear
    box_header "$(printf '%s' "${mode^^}") SSH ACCOUNT"
    echo ""
    box_top
    box_kv "Username Info" "$user"
    box_kv "Expired Account" "$exp"
    box_kv "Status $word" "Success"
    box_kv "Message" "Terima kasih telah menggunakan layanan kami"
    box_bottom
    echo ""
    notify_event "${mode^^}" "$user" "SSH" "Manual (admin)"
}

cmd_ssh_cek() {
    TITLE="SSH"
    local sess total=0 u t c
    clear
    box_header "CHECK ONLINE SSH"
    echo ""
    sess=$(ssh_sessions)
    if [[ -n "$sess" ]]; then
        while IFS='|' read -r u t c; do
            [[ -z "$u" ]] && continue
            box_top
            box_kv "Username" "$u"
            box_kv "Last Login" "$t"
            box_kv "Limit Login" "$(ssh_limit_label "$(ssh_limit_get "$u")")"
            box_kv "User Login" "$c"
            box_kv "Expired" "$(ssh_day_label "$(ssh_exp_day "$u")")"
            box_bottom
            echo ""
            total=$((total + 1))
        done < <(printf '%s\n' "$sess" | awk -F'|' '{c[$1]++; if ($3 > t[$1]) t[$1]=$3} END{for (u in c) print u"|"t[u]"|"c[u]}' | sort)
    fi
    if [[ $total -eq 0 ]]; then
        print_error "No users currently online"
    else
        box_top
        box_center "Total User Online :${GREEN} $total"
        box_bottom
    fi
    echo ""
}

cmd_ssh_list() {
    TITLE="SSH"
    clear
    box_header "LIST SSH ACCOUNT"
    echo ""
    ssh_list_users || return 0
    show_users
}

ssh_default_banner() {
    cat <<'BANNER_EOF'
<p style="text-align:center">

<font color="#FF0059">════════════════════════════════════</font><br>

<font color="#00E5FF"><b>        ✦ WELCOME TO SSH SERVER ✦        </b></font><br>
<font color="#FFD700"><b>            ACCESS GRANTED               </b></font><br>

<font color="#FFFFFF">────────────────────────────────────────</font><br>

<font color="#FF4D4D"><b>⚠ TERMS OF SERVICE ⚠</b></font><br><br>

<font color="#00FF9C">✓ NO SPAM</font><br>
<font color="#00FF9C">✓ NO DDOS ATTACK</font><br>
<font color="#00FF9C">✓ NO HACKING / CARDING</font><br>
<font color="#00FF9C">✓ NO TORRENT</font><br>
<font color="#00FF9C">✓ NO MULTI LOGIN</font><br>

<br>
<font color="#FFFFFF">────────────────────────────────────────</font><br>

<font color="#FF0059"><b>VIOLATION = ACCOUNT TERMINATED</b></font><br>

<font color="#FF0059">════════════════════════════════════</font>

</p>
BANNER_EOF
}

ssh_apply_banner() {
    local bflag=""
    [[ -s "$BANNER_FILE" ]] && bflag=" -b $BANNER_FILE"
    cat > "$DROPBEAR_UNIT" <<UNIT_EOF
[Unit]
Description=Dropbear (127.0.0.1:109) untuk SSH WebSocket
After=network.target

[Service]
ExecStart=${DROPBEAR_BIN} -F -E -R -w${bflag} -p 127.0.0.1:109
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
UNIT_EOF
    systemctl daemon-reload >/dev/null 2>&1
    systemctl restart dropbear-ws >/dev/null 2>&1
    sleep 1
    systemctl is-active --quiet dropbear-ws
}

ssh_banner_set() {
    local new="$1" size bak
    size=$(wc -c < "$new")
    if (( size > BANNER_MAX )); then
        print_error "Banner $size byte, melebihi batas $BANNER_MAX byte (dropbear menolak start jika lebih besar)"
        return 1
    fi
    mkdir -p "$(dirname "$BANNER_FILE")"
    bak=$(mktemp)
    [[ -f "$BANNER_FILE" ]] && cp -f "$BANNER_FILE" "$bak" || : > "$bak"
    cp -f "$new" "$BANNER_FILE"
    chmod 644 "$BANNER_FILE"
    if ssh_apply_banner; then
        rm -f "$bak"
        return 0
    fi
    cp -f "$bak" "$BANNER_FILE"
    ssh_apply_banner
    rm -f "$bak"
    print_error "Dropbear gagal start dengan banner baru, banner lama dikembalikan"
    return 1
}

ssh_banner_init() {
    local t
    if [[ ! -s "$BANNER_FILE" ]]; then
        t=$(mktemp)
        ssh_default_banner > "$t"
        ssh_banner_set "$t"
        rm -f "$t"
    else
        ssh_apply_banner
    fi
}

cmd_ssh_banner() {
    local opt tmp size status
    while :; do
        size=0
        [[ -f "$BANNER_FILE" ]] && size=$(wc -c < "$BANNER_FILE")
        if (( size > 0 )); then status="Aktif ($size / $BANNER_MAX byte)"; else status="Tidak aktif"; fi
        clear
        box_header "BANNER SSH (DROPBEAR)"
        box_top
        box_kv "Status" "$status"
        box_kv "File" "$BANNER_FILE"
        box_text "Banner mendukung HTML (mis. <font color>, <br>, <b>)."
        box_bottom
        box_top2
        box_menu2 "1" "Lihat Banner" "3" "Tempel Banner Baru"
        box_menu2 "2" "Edit dengan nano" "4" "Pakai Banner Contoh"
        box_menu2 "5" "Matikan Banner" "0" "Kembali"
        box_bottom2
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1)
                echo ""
                if (( size > 0 )); then cat "$BANNER_FILE"; else print_warning "Banner belum diatur"; fi
                echo ""
                ui_pause "Press any key to continue" ;;
            2)
                if ! command -v nano >/dev/null 2>&1; then
                    echo ""; print_error "nano belum terpasang (apt-get install -y nano). Pakai opsi 3 untuk menempel banner."
                    ui_pause "Press any key to continue"; continue
                fi
                tmp=$(mktemp)
                [[ -f "$BANNER_FILE" ]] && cp -f "$BANNER_FILE" "$tmp"
                nano "$tmp"
                echo ""
                if [[ ! -s "$tmp" ]]; then
                    print_warning "Banner kosong, tidak ada yang diubah (pakai opsi 5 untuk mematikan)"
                elif ssh_banner_set "$tmp"; then
                    print_success "Banner diperbarui"
                fi
                rm -f "$tmp"
                ui_pause "Press any key to continue" ;;
            3)
                echo ""
                print_info "Tempel banner di bawah ini. Setelah selesai, ketik EOF pada baris baru lalu Enter."
                echo ""
                tmp=$(mktemp)
                local line
                while IFS= read -r line; do
                    [[ "$line" == "EOF" ]] && break
                    printf '%s\n' "$line" >> "$tmp"
                done
                echo ""
                if [[ ! -s "$tmp" ]]; then
                    print_warning "Tidak ada isi, banner tidak diubah"
                elif ssh_banner_set "$tmp"; then
                    print_success "Banner diperbarui ($(wc -c < "$BANNER_FILE") byte)"
                fi
                rm -f "$tmp"
                ui_pause "Press any key to continue" ;;
            4)
                echo ""
                tmp=$(mktemp)
                ssh_default_banner > "$tmp"
                if ssh_banner_set "$tmp"; then print_success "Banner contoh dipasang"; fi
                rm -f "$tmp"
                ui_pause "Press any key to continue" ;;
            5)
                echo ""
                tmp=$(mktemp)
                : > "$tmp"
                : > "$BANNER_FILE"
                if ssh_apply_banner; then print_success "Banner dimatikan"; else print_error "Gagal menerapkan perubahan"; fi
                rm -f "$tmp"
                ui_pause "Press any key to continue" ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1 ;;
        esac
    done
}

cmd_setdomain() {
    local old="$DOMAIN" new yn ip_new ip_srv acme certdir ok=0 log="/tmp/mzb-setdomain.log"
    acme="${ACME_BIN:-$HOME/.acme.sh/acme.sh}"
    certdir="${CERT_DIR:-/var/lib/marzban/certs}"
    clear
    box_header "UBAH DOMAIN"
    box_top
    box_kv "Domain saat ini" "$old"
    box_bottom
    echo ""
    read -rp "$(prompt_str "Domain baru (sama = terbitkan ulang sertifikat)")" -e new
    new="${new,,}"
    if [[ ! "$new" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
        echo ""; print_error "Format domain tidak valid"; echo ""; return 1
    fi
    if [[ ! -x "$acme" ]]; then
        echo ""; print_error "acme.sh tidak ditemukan di $acme (sertifikat dulu diterbitkan dengan cara lain?)"; echo ""; return 1
    fi
    ip_new=$(getent ahostsv4 "$new" 2>/dev/null | awk 'NR==1{print $1}')
    ip_srv=$(curl -s -m 5 https://api.ipify.org 2>/dev/null)
    [[ "$ip_srv" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || ip_srv=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo ""
    box_top
    box_kv "Domain baru" "$new"
    box_kv "IP domain baru" "${ip_new:-tidak ditemukan}"
    box_kv "IP server" "${ip_srv:--}"
    box_bottom
    echo ""
    if [[ -z "$ip_new" ]]; then
        print_error "Domain belum punya record DNS. Arahkan dulu ke server ini."; echo ""; return 1
    fi
    [[ "$ip_new" != "$ip_srv" ]] && print_warning "IP domain berbeda dari IP server (wajar jika memakai proxy Cloudflare)"
    print_warning "Marzban dihentikan sekitar 1 menit untuk menerbitkan sertifikat"
    [[ "$new" != "$old" ]] && print_warning "Link akun yang dibuat dengan domain lama tidak berlaku lagi"
    echo ""
    read -rp "$(prompt_str "Lanjutkan? (y/N)")" yn
    [[ "$yn" =~ ^[yY]$ ]] || { echo ""; print_warning "Dibatalkan"; echo ""; return 0; }

    mkdir -p "$certdir/backup"
    cp -f "$certdir/fullchain.pem" "$certdir/key.pem" "$certdir/backup/" 2>/dev/null
    echo ""
    print_info "Menerbitkan sertifikat untuk $new ..."
    marzban down >/dev/null 2>&1
    if "$acme" --issue --force --standalone -d "$new" --keylength ec-256 --server letsencrypt \
            --pre-hook "marzban down >/dev/null 2>&1 || true" --post-hook "marzban up -n >/dev/null 2>&1 || true" > "$log" 2>&1 \
       && "$acme" --install-cert -d "$new" --ecc \
            --fullchain-file "$certdir/fullchain.pem" --key-file "$certdir/key.pem" >> "$log" 2>&1; then
        ok=1
    fi
    if (( ! ok )); then
        cp -f "$certdir/backup/fullchain.pem" "$certdir/backup/key.pem" "$certdir/" 2>/dev/null
        marzban up -n >/dev/null 2>&1
        print_error "Gagal menerbitkan sertifikat. Pengaturan lama dipertahankan."
        print_info "Log lengkap: $log"
        tail -n 4 "$log" 2>/dev/null
        echo ""
        return 1
    fi

    if [[ "$new" != "$old" ]]; then
        conf_set DOMAIN "$new"
        if [[ -f "$ENV_FILE" ]]; then
            if grep -qE '^XRAY_SUBSCRIPTION_URL_PREFIX' "$ENV_FILE"; then
                sed -i -E "s#^XRAY_SUBSCRIPTION_URL_PREFIX.*#XRAY_SUBSCRIPTION_URL_PREFIX = \"https://${new}\"#" "$ENV_FILE"
            else
                echo "XRAY_SUBSCRIPTION_URL_PREFIX = \"https://${new}\"" >> "$ENV_FILE"
            fi
        fi
        "$acme" --remove -d "$old" --ecc >/dev/null 2>&1
    fi
    marzban restart -n >/dev/null 2>&1
    echo ""
    print_success "Selesai. Domain: $new"
    print_info "Dashboard: https://$new/dashboard/"
    echo ""
}

ssl_free_port80() {
    # acme.sh --standalone butuh port 80 kosong: hentikan web server lain / proses yang memakainya
    local svc pids pid name i
    for svc in nginx apache2 httpd caddy lighttpd; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            print_info "Menghentikan $svc (memakai port 80)"
            systemctl stop "$svc" >/dev/null 2>&1
        fi
    done
    for i in 1 2 3 4 5 6; do
        pids=$(ss -H -ltnp 'sport = :80' 2>/dev/null | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u | grep -vxE "1|$$")
        [[ -z "$pids" ]] && return 0
        for pid in $pids; do
            name=$(ps -o comm= -p "$pid" 2>/dev/null)
            (( i == 1 )) && print_warning "Port 80 dipakai ${name:-proses} (PID $pid), dimatikan"
            if (( i <= 3 )); then kill "$pid" >/dev/null 2>&1; else kill -9 "$pid" >/dev/null 2>&1; fi
        done
        sleep 1
    done
    pids=$(ss -H -ltnp 'sport = :80' 2>/dev/null | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u | grep -vxE "1|$$")
    [[ -z "$pids" ]]
}

ssl_status() {
    # mengisi SSL_END, SSL_DAYS, SSL_HOST, SSL_KEY ("Ya"/"Tidak"/"-")
    local cert="$1" key="$2" domain="$3" end end_ts
    SSL_END="-"; SSL_DAYS=""; SSL_HOST="-"; SSL_KEY="-"
    command -v openssl >/dev/null 2>&1 || return 1
    [[ -s "$cert" ]] || return 1
    end=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2)
    end_ts=$(date -d "$end" +%s 2>/dev/null)
    if [[ "$end_ts" =~ ^[0-9]+$ ]]; then
        SSL_END=$(date -d "@$end_ts" '+%Y-%m-%d')
        SSL_DAYS=$(( (end_ts - $(date +%s)) / 86400 ))
    fi
    if openssl x509 -in "$cert" -noout -checkhost "$domain" 2>/dev/null | grep -q 'does match'; then
        SSL_HOST="Ya"
    else
        SSL_HOST="Tidak"
    fi
    if [[ -s "$key" ]]; then
        if [[ "$(openssl x509 -in "$cert" -noout -pubkey 2>/dev/null | openssl md5 2>/dev/null)" \
           == "$(openssl pkey -in "$key" -pubout 2>/dev/null | openssl md5 2>/dev/null)" ]]; then
            SSL_KEY="Ya"
        else
            SSL_KEY="Tidak"
        fi
    else
        SSL_KEY="Tidak"
    fi
    return 0
}

cmd_fixssl() {
    local domain="$DOMAIN" acme certdir cert key log="/tmp/mzb-fixssl.log" ok=0 yn ip_dom ip_srv label healthy=0
    acme="${ACME_BIN:-$HOME/.acme.sh/acme.sh}"
    certdir="${CERT_DIR:-$MZB_DATA/certs}"
    cert="$certdir/fullchain.pem"
    key="$certdir/key.pem"
    clear
    box_header "FIX SSL"
    if [[ -z "$domain" ]]; then
        echo ""; print_error "Domain belum diatur"; echo ""; return 1
    fi
    if [[ ! -x "$acme" ]]; then
        echo ""; print_error "acme.sh tidak ditemukan di $acme"; echo ""; return 1
    fi

    ip_dom=$(getent ahostsv4 "$domain" 2>/dev/null | awk 'NR==1{print $1}')
    ip_srv=$(curl -s -m 5 https://api.ipify.org 2>/dev/null)
    [[ "$ip_srv" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || ip_srv=$(hostname -I 2>/dev/null | awk '{print $1}')

    if ssl_status "$cert" "$key" "$domain"; then
        label="$SSL_END"
        [[ -n "$SSL_DAYS" ]] && label="$SSL_END ($SSL_DAYS hari lagi)"
        [[ "$SSL_HOST" == "Ya" && "$SSL_KEY" == "Ya" && "$SSL_DAYS" =~ ^-?[0-9]+$ ]] && (( SSL_DAYS >= 15 )) && healthy=1
    else
        label="sertifikat tidak ditemukan / tidak terbaca"
    fi
    box_top
    box_kv "Domain" "$domain"
    box_kv "IP domain" "${ip_dom:-tidak ditemukan}"
    box_kv "IP server" "${ip_srv:--}"
    box_kv "Masa berlaku" "$label"
    box_kv "Cocok domain" "$SSL_HOST"
    box_kv "Cocok kunci" "$SSL_KEY"
    box_bottom
    echo ""
    if [[ -z "$ip_dom" ]]; then
        print_error "Domain belum punya record DNS. Arahkan dulu ke server ini."; echo ""; return 1
    fi
    [[ "$ip_dom" != "$ip_srv" ]] && print_warning "IP domain berbeda dari IP server (wajar jika memakai proxy Cloudflare)"
    if (( healthy )); then
        print_info "Sertifikat terlihat normal. Menerbitkan ulang tidak perlu kecuali ada masalah."
    fi
    print_warning "Marzban dihentikan sekitar 1 menit untuk menerbitkan ulang sertifikat"
    echo ""
    read -rp "$(prompt_str "Terbitkan ulang sertifikat? (y/N)")" yn
    [[ "$yn" =~ ^[yY]$ ]] || { echo ""; print_warning "Dibatalkan"; echo ""; return 0; }

    mkdir -p "$certdir/backup"
    cp -pf "$cert" "$key" "$certdir/backup/" 2>/dev/null
    echo ""
    print_info "Menerbitkan sertifikat untuk $domain ..."
    marzban down >/dev/null 2>&1
    : > "$log"
    if ssl_free_port80 \
       && "$acme" --issue --force --standalone -d "$domain" --keylength ec-256 --server letsencrypt \
            --pre-hook "marzban down >/dev/null 2>&1 || true" --post-hook "marzban up -n >/dev/null 2>&1 || true" > "$log" 2>&1 \
       && "$acme" --install-cert -d "$domain" --ecc \
            --fullchain-file "$cert" --key-file "$key" >> "$log" 2>&1; then
        ok=1
    fi
    if (( ! ok )); then
        cp -pf "$certdir/backup/fullchain.pem" "$certdir/backup/key.pem" "$certdir/" 2>/dev/null
        marzban up -n >/dev/null 2>&1
        print_error "Gagal memperbaiki SSL. Sertifikat lama dipertahankan."
        print_info "Log lengkap: $log"
        grep -iE 'error|fail|invalid|timeout|rate ?limit|too many|refused|unauthorized|verify|cannot|not found|denied|retry' "$log" 2>/dev/null | grep -v 'Container ' | tail -n 8
        echo ""
        return 1
    fi

    marzban restart -n >/dev/null 2>&1
    echo ""
    if ssl_status "$cert" "$key" "$domain"; then
        print_success "SSL berhasil diperbaiki. Berlaku sampai $SSL_END (${SSL_DAYS:-?} hari lagi)"
    else
        print_success "SSL berhasil diterbitkan ulang"
    fi
    echo ""
}

ensure_zip() {
    command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && return 0
    print_info "Memasang zip dan unzip..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y zip unzip >/dev/null 2>&1
    command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1
}

backup_create() {
    local name="${1:-backup-$(date +%F).zip}" stage u uid gid h e
    ensure_zip || { print_error "zip/unzip tidak tersedia"; return 1; }
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
    BK_FILE="$BACKUP_DIR/$name"
    stage=$(mktemp -d)
    mkdir -p "$stage/marzban" "$stage/tools/state" "$stage/ssh" "$stage/meta"

    if [[ -d "$MZB_DATA" ]]; then
        (cd "$MZB_DATA" && tar cf - --exclude='access.log*' --exclude='db.sqlite3*' --exclude='*.sock' .) \
            | tar xf - -C "$stage/marzban"
    fi
    if [[ -f "$MZB_DATA/db.sqlite3" ]]; then
        python3 - "$MZB_DATA/db.sqlite3" "$stage/marzban/db.sqlite3" <<'PY'
import sqlite3, sys
src = sqlite3.connect(sys.argv[1])
dst = sqlite3.connect(sys.argv[2])
src.backup(dst)
dst.close()
src.close()
PY
    fi
    [[ -f "$MZB_APP/.env" ]] && cp -f "$MZB_APP/.env" "$stage/marzban/app.env"
    [[ -f "$MZB_APP/docker-compose.yml" ]] && cp -f "$MZB_APP/docker-compose.yml" "$stage/marzban/app.docker-compose.yml"

    [[ -f "$CONF" ]] && cp -f "$CONF" "$stage/tools/marzban-cli.conf"
    [[ -d "$STATE_DIR" ]] && cp -a "$STATE_DIR/." "$stage/tools/state/"
    [[ -f "$BANNER_FILE" ]] && cp -f "$BANNER_FILE" "$stage/tools/banner"

    BK_SSH_COUNT=0
    : > "$stage/ssh/users.txt"
    while IFS='|' read -r u uid gid; do
        [[ -z "$u" ]] && continue
        h=$(getent shadow "$u" | cut -d: -f2)
        e=$(getent shadow "$u" | cut -d: -f8)
        printf '%s|%s|%s|%s|%s\n' "$u" "$uid" "$gid" "$h" "$e" >> "$stage/ssh/users.txt"
        BK_SSH_COUNT=$((BK_SSH_COUNT + 1))
    done < <(awk -F: '$3>=1000 && $3<65534 && $7=="/bin/false"{print $1"|"$3"|"$4}' /etc/passwd)

    {
        echo "format=1"
        echo "date=$(date '+%Y-%m-%d %H:%M:%S')"
        echo "domain=${DOMAIN:-}"
        echo "host=$(hostname)"
        echo "ssh_users=$BK_SSH_COUNT"
    } > "$stage/meta/info.txt"

    rm -f "$BK_FILE"
    if [[ -n "$BK_PASS" ]]; then
        (cd "$stage" && zip -qr -P "$BK_PASS" "$BK_FILE" .)
    else
        (cd "$stage" && zip -qr "$BK_FILE" .)
    fi
    local rc=$?
    rm -rf "$stage"
    chmod 600 "$BK_FILE" 2>/dev/null
    return $rc
}

backup_send() {
    [[ -n "$BK_TOKEN" && -n "$BK_CHATID" ]] || return 2
    local r
    r=$(curl -s -m 120 -F "chat_id=${BK_CHATID}" -F "caption=$2" -F "document=@$1" \
        "${TG_API}/bot${BK_TOKEN}/sendDocument")
    [[ "$r" == *'"ok":true'* ]]
}

backup_prune() {
    ls -1t "$BACKUP_DIR"/backup-*.zip 2>/dev/null | tail -n +$((BACKUP_KEEP + 1)) | xargs -r rm -f
}

backup_remove_local() {
    # hapus file backup (dan foldernya jika sudah kosong) setelah backup terkirim
    rm -f "$1"
    rmdir "$BACKUP_DIR" 2>/dev/null
    return 0
}

backup_cron_apply() {
    if [[ "$BK_AUTO" == "on" ]]; then
        printf '0 %s * * * root /usr/local/bin/mzb-tools autobackup >> %s 2>&1\n' "$BACKUP_HOUR" "$BACKUP_LOG" > "$BACKUP_CRON"
        chmod 644 "$BACKUP_CRON"
        systemctl is-active --quiet cron 2>/dev/null || systemctl enable --now cron >/dev/null 2>&1
    else
        rm -f "$BACKUP_CRON"
    fi
}

backup_size_label() {
    local b
    b=$(stat -c %s "$1" 2>/dev/null || echo 0)
    if (( b >= 1048576 )); then printf '%s MB' $(( (b + 1048575) / 1048576 )); else printf '%s KB' $(( (b + 1023) / 1024 )); fi
}

cmd_backup_now() {
    local rc caption
    clear
    box_header "BACKUP SEKARANG"
    echo ""
    print_info "Membuat backup..."
    if ! backup_create; then
        echo ""; print_error "Gagal membuat backup"; echo ""; return 1
    fi
    backup_prune
    echo ""
    box_top
    box_kv "File" "$BK_FILE"
    box_kv "Ukuran" "$(backup_size_label "$BK_FILE")"
    box_kv "Akun SSH" "$BK_SSH_COUNT"
    box_kv "Password zip" "$([[ -n "$BK_PASS" ]] && echo Ya || echo Tidak)"
    box_bottom
    echo ""
    caption="BACKUP MARZBAN | ${DOMAIN:-} | $(date '+%Y-%m-%d %H:%M')"
    backup_send "$BK_FILE" "$caption"
    rc=$?
    if (( rc == 0 )); then
        print_success "Backup terkirim ke Telegram"
        backup_remove_local "$BK_FILE"
        print_info "File backup di server dihapus otomatis"
    elif (( rc == 2 )); then
        print_warning "Bot backup belum diatur, file hanya tersimpan di server"
    else
        print_error "Gagal mengirim ke Telegram (cek token, chat ID, dan ukuran file maks 50 MB)"
    fi
    echo ""
}

cmd_autobackup() {
    [[ "$BK_AUTO" == "on" ]] || exit 0
    local rc
    echo "$(date '+%Y-%m-%d %H:%M:%S') backup dimulai"
    if backup_create; then
        backup_prune
        backup_send "$BK_FILE" "AUTO BACKUP MARZBAN | ${DOMAIN:-} | $(date '+%Y-%m-%d %H:%M')"
        rc=$?
        case "$rc" in
            0) backup_remove_local "$BK_FILE"
               echo "$(date '+%Y-%m-%d %H:%M:%S') OK $BK_FILE terkirim, file lokal dihapus" ;;
            2) echo "$(date '+%Y-%m-%d %H:%M:%S') OK $BK_FILE (bot belum diatur)" ;;
            *) echo "$(date '+%Y-%m-%d %H:%M:%S') GAGAL kirim $BK_FILE" ;;
        esac
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') GAGAL membuat backup"
    fi
}

restore_ssh_users() {
    local f="$1" u uid gid h e
    RS_ADDED=0; RS_UPDATED=0
    [[ -s "$f" ]] || return 0
    grep -qx '/bin/false' /etc/shells 2>/dev/null || echo '/bin/false' >> /etc/shells
    while IFS='|' read -r u uid gid h e; do
        [[ "$u" =~ ^[a-z_][a-z0-9_-]{1,31}$ ]] || continue
        if ! id "$u" >/dev/null 2>&1; then
            if [[ "$uid" =~ ^[0-9]+$ ]] && ! getent passwd "$uid" >/dev/null 2>&1; then
                useradd -M -s /bin/false -u "$uid" "$u" >/dev/null 2>&1 || continue
            else
                useradd -M -s /bin/false "$u" >/dev/null 2>&1 || continue
            fi
            RS_ADDED=$((RS_ADDED + 1))
        else
            RS_UPDATED=$((RS_UPDATED + 1))
        fi
        [[ -n "$h" ]] || h='!'          # tanpa hash = kunci akun, jangan pernah buat password kosong
        usermod -p "$h" "$u" >/dev/null 2>&1
        if [[ "$e" =~ ^[0-9]+$ ]]; then chage -E "$e" "$u" >/dev/null 2>&1; else chage -E -1 "$u" >/dev/null 2>&1; fi
    done < "$f"
}

restore_create_admin() {
    # Buat ulang admin (sudo) di database hasil restore: marzban cli admin create --sudo
    # Dijalankan tanpa TTY (exec -T) agar jawaban prompt bisa dikirim lewat stdin.
    # Return: 0 = dibuat, 2 = sudah ada (tidak diubah), 1 = gagal
    local user="$1" pass="$2" cf="$MZB_APP/docker-compose.yml" i alog="/tmp/mzb-restore-admin.log"
    local -a compose
    [[ -n "$user" && -n "$pass" ]] || return 1
    if docker compose version >/dev/null 2>&1; then
        compose=(docker compose)
    elif command -v docker-compose >/dev/null 2>&1; then
        compose=(docker-compose)
    else
        return 1
    fi
    _ra_exec() { timeout 90 "${compose[@]}" -f "$cf" -p marzban exec -T "$@"; }
    _ra_exists() {
        local list
        list=$(_ra_exec marzban marzban-cli admin list 2>/dev/null)
        grep -qE "(^|[[:space:]])${user}([[:space:]]|$)" <<<"$list"
    }
    for i in $(seq 1 30); do
        curl -sk -m 3 -o /dev/null "$API_URL/api/admin/token" && break
        sleep 2
    done
    : > "$alog"; chmod 600 "$alog"
    _ra_exists && return 2

    # Cara 1: jawab prompt lewat stdin
    printf '%s\n%s\n%s\n\n\n' "$user" "$pass" "$pass" \
        | _ra_exec marzban marzban-cli admin create --sudo >> "$alog" 2>&1
    _ra_exists && return 0

    # Cara 2: password lewat environment variable
    printf '\n\n' \
        | _ra_exec -e "MARZBAN_ADMIN_PASSWORD=$pass" marzban marzban-cli admin create --sudo --username "$user" >> "$alog" 2>&1
    _ra_exists && return 0

    # Cara 3: pseudo-terminal, jawaban dikirim satu per satu dengan jeda
    {
        sleep 3
        printf '%s\n' "$user"; sleep 1
        printf '%s\n' "$pass"; sleep 1
        printf '%s\n' "$pass"; sleep 1
        printf '\n'; sleep 1
        printf '\n'; sleep 3
    } | timeout 60 script -qec "marzban cli admin create --sudo" /dev/null >> "$alog" 2>&1
    _ra_exists && return 0

    grep -vF -- "$pass" "$alog" | tail -n 3
    return 1
}

cmd_restore() {
    local src="${1:-}" tmp zipf pass x yn r_date r_domain r_ssh safety
    local keep_domain keep_prefix keep_certs certdir tmpenv keep_admin_user keep_admin_pass keep_sudo_user keep_sudo_pass
    clear
    box_header "RESTORE BACKUP"
    echo ""
    if ! command -v marzban >/dev/null 2>&1; then
        print_error "Marzban belum terpasang. Jalankan install.sh dulu, lalu restore."; echo ""; return 1
    fi
    ensure_zip || { print_error "zip/unzip tidak tersedia"; echo ""; return 1; }
    command -v wget >/dev/null 2>&1 || DEBIAN_FRONTEND=noninteractive apt-get install -y wget >/dev/null 2>&1

    if [[ -z "$src" ]]; then
        print_info "Contoh link: http://domain.com/backup-2026-09-04.zip (atau path file zip di server)"
        read -rp "$(prompt_str "Link / path backup")" -e src
    fi
    [[ -n "$src" ]] || { echo ""; print_warning "Dibatalkan"; echo ""; return 0; }

    tmp=$(mktemp -d)
    zipf="$tmp/backup.zip"
    if [[ "$src" =~ ^https?:// ]]; then
        print_info "Mengunduh backup..."
        wget -qO "$zipf" "$src" || { rm -rf "$tmp"; echo ""; print_error "Gagal mengunduh dari link tersebut"; echo ""; return 1; }
    elif [[ -f "$src" ]]; then
        cp -f "$src" "$zipf"
    else
        rm -rf "$tmp"; echo ""; print_error "File atau link tidak ditemukan"; echo ""; return 1
    fi
    [[ -s "$zipf" ]] || { rm -rf "$tmp"; echo ""; print_error "File backup kosong"; echo ""; return 1; }

    pass="$BK_PASS"
    if ! unzip -tqq -P "$pass" "$zipf" >/dev/null 2>&1; then
        read -rsp "$(prompt_str "Password zip")" pass
        echo ""
        if ! unzip -tqq -P "$pass" "$zipf" >/dev/null 2>&1; then
            rm -rf "$tmp"; echo ""; print_error "File bukan zip yang valid, atau password salah"; echo ""; return 1
        fi
    fi
    x="$tmp/x"
    mkdir -p "$x"
    unzip -qo -P "$pass" "$zipf" -d "$x"
    if [[ ! -f "$x/meta/info.txt" || ! -d "$x/marzban" ]]; then
        rm -rf "$tmp"; echo ""; print_error "Ini bukan file backup Marzban Tools yang valid"; echo ""; return 1
    fi
    r_date=$(grep -m1 '^date=' "$x/meta/info.txt" | cut -d= -f2-)
    r_domain=$(grep -m1 '^domain=' "$x/meta/info.txt" | cut -d= -f2-)
    r_ssh=$(grep -m1 '^ssh_users=' "$x/meta/info.txt" | cut -d= -f2-)
    echo ""
    box_top
    box_kv "Tanggal backup" "${r_date:--}"
    box_kv "Domain backup" "${r_domain:--}"
    box_kv "Akun SSH" "${r_ssh:-0}"
    box_kv "Database" "$([[ -f "$x/marzban/db.sqlite3" ]] && echo Ada || echo 'Tidak ada')"
    box_bottom
    echo ""
    print_warning "Data Marzban, pengaturan tools, dan akun SSH di server ini akan ditimpa"
    print_info "Domain, sertifikat, link langganan, dan login admin server ini TIDAK ikut berubah"
    print_info "Backup pengaman kondisi sekarang dibuat otomatis sebelum restore"
    echo ""
    read -rp "$(prompt_str "Lanjutkan restore? (y/N)")" yn
    [[ "$yn" =~ ^[yY]$ ]] || { rm -rf "$tmp"; echo ""; print_warning "Dibatalkan"; echo ""; return 0; }

    safety="pre-restore-$(date +%F-%H%M%S).zip"
    if ! backup_create "$safety"; then
        rm -rf "$tmp"; echo ""; print_error "Gagal membuat backup pengaman, restore dibatalkan"; echo ""; return 1
    fi
    echo ""
    print_info "Backup pengaman: $BK_FILE"
    print_info "Menghentikan Marzban dan menerapkan data..."
    marzban down >/dev/null 2>&1

    keep_domain="$DOMAIN"
    certdir="${CERT_DIR:-$MZB_DATA/certs}"
    keep_prefix=$(grep -E '^XRAY_SUBSCRIPTION_URL_PREFIX' "$ENV_FILE" 2>/dev/null | head -1)
    keep_certs=$(mktemp -d)
    cp -pf "$certdir/fullchain.pem" "$certdir/key.pem" "$keep_certs/" 2>/dev/null
    keep_admin_user="$ADMIN_USER"
    keep_admin_pass="$ADMIN_PASS"
    keep_sudo_user=$(grep -E '^SUDO_USERNAME' "$ENV_FILE" 2>/dev/null | head -1)
    keep_sudo_pass=$(grep -E '^SUDO_PASSWORD' "$ENV_FILE" 2>/dev/null | head -1)

    mkdir -p "$MZB_DATA" "$MZB_APP"
    rm -f "$MZB_DATA/db.sqlite3-wal" "$MZB_DATA/db.sqlite3-shm"
    cp -a "$x/marzban/." "$MZB_DATA/"
    [[ -f "$MZB_DATA/app.env" ]] && mv -f "$MZB_DATA/app.env" "$MZB_APP/.env"
    [[ -f "$MZB_DATA/app.docker-compose.yml" ]] && mv -f "$MZB_DATA/app.docker-compose.yml" "$MZB_APP/docker-compose.yml"

    if [[ -f "$x/tools/marzban-cli.conf" ]]; then
        cp -f "$x/tools/marzban-cli.conf" "$CONF"
        chmod 600 "$CONF"
    fi
    if [[ -d "$x/tools/state" ]]; then
        mkdir -p "$STATE_DIR"
        cp -a "$x/tools/state/." "$STATE_DIR/"
    fi
    if [[ -f "$x/tools/banner" ]]; then
        mkdir -p "$(dirname "$BANNER_FILE")"
        cp -f "$x/tools/banner" "$BANNER_FILE"
    fi
    restore_ssh_users "$x/ssh/users.txt"

    [[ -f "$CONF" ]] && source "$CONF"

    # Domain tidak ikut backup: kembalikan domain, sertifikat, dan prefix langganan milik server ini
    if [[ -n "$keep_domain" ]]; then
        conf_set DOMAIN "$keep_domain"
    fi
    if [[ -f "$keep_certs/fullchain.pem" && -f "$keep_certs/key.pem" ]]; then
        mkdir -p "$certdir"
        cp -pf "$keep_certs/fullchain.pem" "$keep_certs/key.pem" "$certdir/"
    fi
    rm -rf "$keep_certs"
    [[ -n "$keep_admin_user" ]] && conf_set ADMIN_USER "$keep_admin_user"
    [[ -n "$keep_admin_pass" ]] && conf_set ADMIN_PASS "$keep_admin_pass"
    if [[ -f "$ENV_FILE" && ( -n "$keep_sudo_user" || -n "$keep_sudo_pass" ) ]]; then
        tmpenv=$(mktemp)
        grep -vE '^(SUDO_USERNAME|SUDO_PASSWORD)' "$ENV_FILE" > "$tmpenv"
        [[ -n "$keep_sudo_user" ]] && printf '%s\n' "$keep_sudo_user" >> "$tmpenv"
        [[ -n "$keep_sudo_pass" ]] && printf '%s\n' "$keep_sudo_pass" >> "$tmpenv"
        cat "$tmpenv" > "$ENV_FILE"
        rm -f "$tmpenv"
    fi
    if [[ -f "$ENV_FILE" && -n "$keep_domain" ]]; then
        [[ -n "$keep_prefix" ]] || keep_prefix="XRAY_SUBSCRIPTION_URL_PREFIX = \"https://${keep_domain}\""
        tmpenv=$(mktemp)
        grep -vE '^XRAY_SUBSCRIPTION_URL_PREFIX' "$ENV_FILE" > "$tmpenv"
        printf '%s\n' "$keep_prefix" >> "$tmpenv"
        cat "$tmpenv" > "$ENV_FILE"
        rm -f "$tmpenv"
    fi

    ensure_cron >/dev/null 2>&1
    backup_cron_apply
    [[ -f "$DROPBEAR_UNIT" ]] && ssh_apply_banner >/dev/null 2>&1

    marzban up -n >/dev/null 2>&1
    print_info "Membuat ulang admin ${ADMIN_USER} di Marzban..."
    restore_create_admin "$ADMIN_USER" "$ADMIN_PASS"
    case $? in
        0) print_success "Admin $ADMIN_USER berhasil dibuat ulang" ;;
        2) print_info "Admin $ADMIN_USER sudah ada di data backup, tidak diubah (password mengikuti backup)" ;;
        *) print_warning "Gagal membuat admin otomatis. Buat manual: marzban cli admin create --sudo" ;;
    esac
    rm -rf "$tmp"
    echo ""
    box_top
    box_kv "Status" "Restore selesai"
    box_kv "Akun SSH baru" "$RS_ADDED"
    box_kv "Akun SSH diperbarui" "$RS_UPDATED"
    box_bottom
    echo ""
    print_info "Domain tetap: ${DOMAIN:-$keep_domain}${r_domain:+ (domain di backup: $r_domain tidak dipakai)}"
    echo ""
}

cmd_backupmenu() {
    local opt tok chat pw h n last status_bot status_auto
    while :; do
        n=$(ls -1 "$BACKUP_DIR"/backup-*.zip 2>/dev/null | wc -l)
        last=$(ls -1t "$BACKUP_DIR"/backup-*.zip 2>/dev/null | head -1)
        clear
        box_header "BACKUP / RESTORE"
        box_top
        if [[ -n "$BK_TOKEN" && -n "$BK_CHATID" ]]; then
            box_kv "Bot Backup" "Aktif (chat $BK_CHATID)"
        else
            box_kv "Bot Backup" "Belum diatur"
        fi
        if [[ "$BK_AUTO" == "on" ]]; then
            box_kv "Auto Backup" "ON, setiap jam $(printf '%02d' "$BACKUP_HOUR"):00 (waktu server)"
        else
            box_kv "Auto Backup" "OFF"
        fi
        box_kv "Password zip" "$([[ -n "$BK_PASS" ]] && echo Diatur || echo 'Tidak ada')"
        box_kv "Backup lokal" "$n file${last:+ (terakhir: $(basename "$last"))}"
        box_bottom
        box_top2
        box_menu2 "1" "Backup Sekarang" "5" "Atur Jam Backup"
        box_menu2 "2" "Set Token & Chat ID" "6" "Password Zip"
        box_menu2 "3" "Hapus Bot" "7" "Restore via Link"
        box_menu2 "4" "Auto Backup ON/OFF" "8" "Daftar Backup Lokal"
        box_bottom2
        box_top
        box_center "Press [0] or [x] to go back"
        box_bottom
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1) cmd_backup_now; ui_pause "Press any key to continue" ;;
            2)
                echo ""
                read -rp "$(prompt_str "Token Bot (dari @BotFather)")" tok
                if [[ ! "$tok" =~ ^[0-9]+:[A-Za-z0-9_-]{20,}$ ]]; then
                    print_error "Format token tidak valid"; ui_pause "Press any key to continue"; continue
                fi
                read -rp "$(prompt_str "Chat ID")" chat
                if [[ ! "$chat" =~ ^-?[0-9]+$ ]]; then
                    print_error "Chat ID harus angka"; ui_pause "Press any key to continue"; continue
                fi
                conf_set BK_TOKEN "$tok"
                conf_set BK_CHATID "$chat"
                conf_set BK_AUTO "on"
                backup_cron_apply
                echo ""
                local saved="$TG_TOKEN" savedc="$TG_CHATID"
                TG_TOKEN="$BK_TOKEN"; TG_CHATID="$BK_CHATID"
                if tg_send "<b>Bot backup Marzban aktif</b> (auto backup setiap jam $(printf '%02d' "$BACKUP_HOUR"):00)"; then
                    print_success "Tersimpan, auto backup aktif, pesan tes terkirim"
                else
                    print_warning "Tersimpan, tetapi pesan tes gagal. Cek token dan chat ID, dan pastikan sudah menekan Start pada bot"
                fi
                TG_TOKEN="$saved"; TG_CHATID="$savedc"
                ui_pause "Press any key to continue" ;;
            3)
                conf_set BK_TOKEN ""
                conf_set BK_CHATID ""
                echo ""; print_success "Bot backup dihapus (backup tetap dibuat di server jika auto backup ON)"
                ui_pause "Press any key to continue" ;;
            4)
                echo ""
                if [[ "$BK_AUTO" == "on" ]]; then
                    conf_set BK_AUTO "off"; backup_cron_apply; print_success "Auto backup dimatikan"
                else
                    conf_set BK_AUTO "on"; backup_cron_apply
                    print_success "Auto backup dinyalakan, setiap jam $(printf '%02d' "$BACKUP_HOUR"):00 (waktu server)"
                fi
                ui_pause "Press any key to continue" ;;
            5)
                echo ""
                read -rp "$(prompt_str "Jam backup (0-23)")" h
                if [[ "$h" =~ ^[0-9]+$ && "$h" -le 23 ]]; then
                    conf_set BACKUP_HOUR "$((10#$h))"
                    backup_cron_apply
                    print_success "Jam backup diatur ke $(printf '%02d' "$((10#$h))"):00"
                else
                    print_error "Isi angka 0 sampai 23"
                fi
                ui_pause "Press any key to continue" ;;
            6)
                echo ""
                print_info "Password melindungi isi zip (kosongkan untuk menghapus). Zip berisi data sensitif."
                read -rsp "$(prompt_str "Password zip")" pw
                echo ""
                conf_set BK_PASS "$pw"
                if [[ -n "$pw" ]]; then print_success "Password zip diatur"; else print_success "Password zip dihapus"; fi
                ui_pause "Press any key to continue" ;;
            7) cmd_restore ""; ui_pause "Press any key to continue" ;;
            8)
                echo ""
                if (( n > 0 )); then
                    ls -1t "$BACKUP_DIR"/*.zip 2>/dev/null | while read -r f; do
                        printf ' %s  %s\n' "$(backup_size_label "$f")" "$f"
                    done
                else
                    print_warning "Belum ada backup lokal"
                fi
                echo ""
                ui_pause "Press any key to continue" ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1 ;;
        esac
    done
}

run_sub_local() {
    ( "$@" )
    [[ -f "$CONF" ]] && source "$CONF"
}

cmd_sshmenu() {
    local opt
    TITLE="SSH"
    while :; do
        clear
        box_header "SSH WS / DROPBEAR MENU"
        box_top2
        box_menu2 "1" "Add Account" "5" "Delete Account"
        box_menu2 "2" "Renew Account" "6" "Check Online"
        box_menu2 "3" "Trial Account" "7" "Lock Account"
        box_menu2 "4" "List Account" "8" "Unlock Account"
        box_menu2 "9" "Banner SSH" "" ""
        box_bottom2
        box_top
        box_center "Press [0] or [x] to go back"
        box_bottom
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1) run_sub_local cmd_ssh_add ;;
            2) run_sub_local cmd_ssh_renew ;;
            3) run_sub_local cmd_ssh_trial ;;
            4) run_sub_local cmd_ssh_list ;;
            5) run_sub_local cmd_ssh_dell ;;
            6) run_sub_local cmd_ssh_cek ;;
            7) run_sub_local cmd_ssh_lockunlock lock ;;
            8) run_sub_local cmd_ssh_lockunlock unlock ;;
            9) run_sub_local cmd_ssh_banner; continue ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1; continue ;;
        esac
        ui_pause "Press any key to continue"
    done
}

login_quiet() {
    local r
    r=$(curl -sk -m 8 -w '\n%{http_code}' "$API_URL/api/admin/token" \
        --data-urlencode "username=$ADMIN_USER" --data-urlencode "password=$ADMIN_PASS" 2>/dev/null)
    [[ "${r##*$'\n'}" == "200" ]] || { TOKEN=""; return 1; }
    TOKEN=$(printf '%s' "${r%$'\n'*}" | pj 'd["access_token"]')
    [[ -n "$TOKEN" ]]
}

svc_badge() {
    if [[ "$1" == "1" ]]; then printf '%s● Running%s' "$GREEN" "$NC"; else printf '%s○ Stopped%s' "$RED" "$NC"; fi
}

on_off() {
    if [[ "$1" == "1" ]]; then printf '%sON%s' "$GREEN" "$NC"; else printf '%sOFF%s' "$RED" "$NC"; fi
}

load_ipinfo() {
    local age=999999
    mkdir -p "$STATE_DIR"
    [[ -f "$IPINFO_FILE" ]] && age=$(( $(date +%s) - $(stat -c %Y "$IPINFO_FILE") ))
    if (( age > 86400 )); then
        local j
        j=$(curl -s -m 4 "http://ip-api.com/json/?fields=query,city,isp" 2>/dev/null)
        if [[ -n "$j" ]]; then
            printf '%s' "$j" | pj 'd.get("query","-")+"|"+d.get("city","-")+"|"+d.get("isp","-")' > "$IPINFO_FILE" 2>/dev/null
        fi
    fi
    IPINFO=$(cat "$IPINFO_FILE" 2>/dev/null)
    [[ -n "$IPINFO" ]] || IPINFO="$(hostname -I 2>/dev/null | awk '{print $1}')|-|-"
    IP_VPS="${IPINFO%%|*}"
    local rest="${IPINFO#*|}"
    CITY="${rest%%|*}"
    ISP="${rest#*|}"
}

show_main() {
    local os cores ram_used ram_total up c_ws c_vl c_tr c_ssh c_all mz xr cr tg au sw ug
    os=$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}")
    cores=$(nproc 2>/dev/null || echo "-")
    ram_used=$(free -m 2>/dev/null | awk 'NR==2{print $3}')
    ram_total=$(free -m 2>/dev/null | awk 'NR==2{print $2}')
    up=$(uptime -p 2>/dev/null | sed 's/^up //')

    mz=0; docker ps --format '{{.Names}}' 2>/dev/null | grep -qi marzban && mz=1
    xr=0; ss -tln 2>/dev/null | grep -qE ':443\b' && xr=1
    cr=0; systemctl is-active --quiet cron 2>/dev/null && cr=1
    sw=0; systemctl is-active --quiet ws-ssh 2>/dev/null && systemctl is-active --quiet dropbear-ws 2>/dev/null && sw=1
    ug=0; systemctl is-active --quiet udpgw 2>/dev/null && ug=1
    tg=0; [[ -n "$TG_TOKEN" && -n "$TG_CHATID" ]] && tg=1
    au=0; [[ "$AUTO_UNLOCK" == "on" ]] && au=1

    c_ssh=$(ssh_users | wc -l)
    c_ws="-"; c_vl="-"; c_tr="-"
    if [[ -n "$TOKEN" ]]; then
        api GET "/api/users?limit=1000"
        if [[ "$CODE" == "200" ]]; then
            c_all=$(printf '%s' "$BODY" | python3 -c '
import sys, json
d = json.load(sys.stdin)
c = {"vmess": 0, "vless": 0, "trojan": 0}
for u in d.get("users", []):
    for k in (u.get("proxies") or {}):
        if k in c:
            c[k] += 1
print(c["vmess"], c["vless"], c["trojan"])' 2>/dev/null)
            read -r c_ws c_vl c_tr <<< "$c_all"
        fi
    fi

    clear
    box_header "SYSTEM INFORMATION"
    box_top
    box_kv "System OS" "$os"
    box_kv "Core CPU" "$cores"
    box_kv "Server RAM" "${ram_used:-?} MB / ${ram_total:-?} MB"
    box_kv "Uptime" "${up:--}"
    box_kv "City" "$CITY"
    box_kv "Domain" "$DOMAIN"
    box_kv "IP VPS" "$IP_VPS"
    box_kv "ISP" "$ISP"
    box_bottom

    box_top
    box_line "${WHITE}MARZBAN${NC} : $(svc_badge "$mz")    ${WHITE}XRAY${NC} : $(svc_badge "$xr")"
    box_line "${WHITE}CRON${NC}    : $(svc_badge "$cr")    ${WHITE}BOT${NC}  : $(on_off "$tg")   ${WHITE}AUTO UNLOCK${NC} : $(on_off "$au")"
    box_line "${WHITE}SSH WS${NC}  : $(svc_badge "$sw")    ${WHITE}UDPGW${NC} : $(svc_badge "$ug")"
    box_line "${WHITE}AKUN${NC}    : SSH ${GREEN}${c_ssh}${NC}   VMESS ${GREEN}${c_ws}${NC}   VLESS ${GREEN}${c_vl}${NC}   TROJAN ${GREEN}${c_tr}${NC}"
    box_bottom

    box_top2
    box_menu2 "1" "SSH WS / DROPBEAR" "7" "FIX SSL"
    box_menu2 "2" "VMESS / XRAY" "8" "AUTO UNLOCK"
    box_menu2 "3" "VLESS / XRAY" "9" "MARZBAN"
    box_menu2 "4" "TROJAN / XRAY" "10" "SETUP LOGIN"
    box_menu2 "5" "LOCK / UNLOCK" "11" "LOG LIMIT IP"
    box_menu2 "6" "MENU BOT" "12" "UBAH DOMAIN"
    box_menu2 "13" "BACKUP / RESTORE" "" ""
    box_bottom2
    echo ""
}

run_sub() {
    ( [[ -n "$TOKEN" ]] || login; "$@" )
    [[ -f "$CONF" ]] && source "$CONF"
}

cmd_list() {
    clear
    box_header "LIST $TITLE ACCOUNT"
    echo ""
    list_users || return 0
    show_users
}

cmd_protomenu() {
    local opt
    set_proto "$1"
    while :; do
        clear
        box_header "$TITLE / XRAY MENU"
        box_top2
        box_menu2 "1" "Add Account" "4" "Trial Account"
        box_menu2 "2" "Renew Account" "5" "Delete Account"
        box_menu2 "3" "Check Online" "6" "List Account"
        box_bottom2
        box_top
        box_center "Press [0] or [x] to go back"
        box_bottom
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1) run_sub cmd_add ;;
            2) run_sub cmd_renew ;;
            3) run_sub cmd_cek ;;
            4) run_sub cmd_trial ;;
            5) run_sub cmd_dell ;;
            6) run_sub cmd_list ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1; continue ;;
        esac
        ui_pause "Press any key to continue"
    done
}

cek_all() {
    local p
    for p in ws vl tr; do
        set_proto "$p"
        cmd_cek
    done
    cmd_ssh_cek
}

cmd_marzbanmenu() {
    local opt cname
    while :; do
        clear
        box_header "MENU MARZBAN"
        box_top2
        box_menu2 "1" "Status Marzban" "3" "Lihat Log"
        box_menu2 "2" "Restart Marzban" "0" "Kembali"
        box_bottom2
        echo ""
        read -rp "$(prompt_str "Select option")" opt
        case "$opt" in
            1) echo ""; marzban status ;;
            2) echo ""; marzban restart -n ;;
            3)
                echo ""
                cname=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i marzban | head -1)
                if [[ -n "$cname" ]]; then
                    docker logs --tail 40 "$cname" 2>&1
                else
                    print_error "Container Marzban tidak ditemukan"
                fi ;;
            0|x|X) return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1; continue ;;
        esac
        echo ""
        ui_pause "Press any key to continue"
    done
}

show_iplimit_log() {
    clear
    box_header "LOG LIMIT IP"
    echo ""
    if [[ -s "$IPLIMIT_LOG" ]]; then
        tail -n 20 "$IPLIMIT_LOG"
    else
        print_warning "Belum ada kejadian lock/unlock otomatis"
    fi
    echo ""
}

cmd_mainmenu() {
    local opt
    load_ipinfo
    while :; do
        login_quiet
        show_main
        read -rp "$(prompt_str "Select Options [1-13 / x to exit]")" opt
        case "$opt" in
            1) cmd_sshmenu ;;
            2) cmd_protomenu ws ;;
            3) cmd_protomenu vl ;;
            4) cmd_protomenu tr ;;
            5) run_sub cmd_menulock ;;
            6) cmd_setbot ;;
            7) run_sub_local cmd_fixssl; ui_pause "Press any key to continue" ;;
            8) cmd_setunlock ;;
            9) cmd_marzbanmenu ;;
            10) run_sub setup_conf; ui_pause "Press any key to continue" ;;
            11) show_iplimit_log; ui_pause "Press any key to continue" ;;
            12) run_sub_local cmd_setdomain; ui_pause "Press any key to continue" ;;
            13) run_sub_local cmd_backupmenu ;;
            0|x|X) clear; return 0 ;;
            *) print_error "Pilihan anda tidak tersedia"; sleep 1 ;;
        esac
    done
}

cmd_autostart() {
    local rc="${MZB_RC:-/root/.bashrc}"
    case "$1" in
        on)
            if ! grep -q '>>> mzb-menu >>>' "$rc" 2>/dev/null; then
                cat >> "$rc" <<'RC_EOF'

# >>> mzb-menu >>>
if [[ $- == *i* && -t 0 && -t 1 && -z "$MZB_MENU_SHOWN" && -x /usr/local/bin/menu ]]; then
    export MZB_MENU_SHOWN=1
    /usr/local/bin/menu
fi
# <<< mzb-menu <<<
RC_EOF
            fi
            print_success "Menu akan terbuka otomatis saat login berikutnya" ;;
        off)
            sed -i '/# >>> mzb-menu >>>/,/# <<< mzb-menu <<</d' "$rc" 2>/dev/null
            print_success "Menu otomatis dimatikan. Buka manual dengan perintah: menu" ;;
        *)
            if grep -q '>>> mzb-menu >>>' "$rc" 2>/dev/null; then
                print_info "Menu otomatis: ON (matikan: mzb-tools autostart off)"
            else
                print_info "Menu otomatis: OFF (nyalakan: mzb-tools autostart on)"
            fi ;;
    esac
}

show_help() {
    clear
    box_header "MARZBAN TOOLS"
    box_top
    box_text "Buat akun   : addws    addvl    addtr"
    box_text "Perpanjang  : renewws  renewvl  renewtr"
    box_text "Hapus akun  : dellws   dellvl   delltr"
    box_text "Akun trial  : trialws  trialvl  trialtr (auto hapus)"
    box_text "Cek online  : cekws    cekvl    cektr"
    box_text "Kunci akun  : lockws   lockvl   locktr"
    box_text "Buka kunci  : unlockws unlockvl unlocktr"
    box_text "Menu lock   : menulock"
    box_text "Setting     : setbot (notif Telegram), setunlock"
    box_text "Akun SSH    : addssh renewssh dellssh trialssh"
    box_text "              cekssh lockssh unlockssh"
    box_text "Backup      : menubackup  backup  restore"
    box_text "Banner SSH  : bannerssh"
    box_text "Ubah domain : setdomain"
    box_text "Fix SSL     : menu utama no. 7"
    box_text "Menu utama  : menu"
    box_mid
    box_text "ws = VMess, vl = VLESS, tr = Trojan"
    box_text "Limit IP (Xray) / Limit Login (SSH) dicek tiap menit"
    box_text "Melebihi batas = akun dikunci otomatis"
    box_text "Atur ulang  : mzb-tools setup"
    box_bottom
    echo ""
}

NAME="${MZB_COMMAND:-$(basename "$0")}"
ARG1="${1:-}"

if [[ "$NAME" == "mzb-tools"* || "$NAME" == "mzb-tools-core.sh" ]]; then
    case "$1" in
        setup) setup_conf; exit 0 ;;
        autostart) cmd_autostart "$2"; exit 0 ;;
        banner-init) ssh_banner_init; exit $? ;;
        autobackup)
            [[ -f "$CONF" ]] || exit 0
            source "$CONF"
            cmd_autobackup
            exit 0 ;;
        cleanup|iplimit)
            [[ -f "$CONF" ]] || exit 0
            source "$CONF"
            ensure_cron >/dev/null 2>&1
            if [[ "$1" == "cleanup" ]]; then cmd_cleanup; else cmd_iplimit; fi
            exit 0 ;;
        *) show_help; exit 0 ;;
    esac
fi

case "$NAME" in
    addws|addvl|addtr)             ACTION=add;    set_proto "${NAME: -2}" ;;
    renewws|renewvl|renewtr)       ACTION=renew;  set_proto "${NAME: -2}" ;;
    dellws|dellvl|delltr)          ACTION=dell;   set_proto "${NAME: -2}" ;;
    trialws|trialvl|trialtr)       ACTION=trial;  set_proto "${NAME: -2}" ;;
    cekws|cekvl|cektr)             ACTION=cek;    set_proto "${NAME: -2}" ;;
    lockws|lockvl|locktr)          ACTION=lock;   set_proto "${NAME: -2}" ;;
    unlockws|unlockvl|unlocktr)    ACTION=unlock; set_proto "${NAME: -2}" ;;
    addssh)    ACTION=ssh_add ;;
    renewssh)  ACTION=ssh_renew ;;
    dellssh)   ACTION=ssh_dell ;;
    trialssh)  ACTION=ssh_trial ;;
    cekssh)    ACTION=ssh_cek ;;
    lockssh)   ACTION=ssh_lock ;;
    unlockssh) ACTION=ssh_unlock ;;
    bannerssh) ACTION=ssh_banner ;;
    menubackup) ACTION=backupmenu ;;
    backup)    ACTION=backup_now ;;
    restore)   ACTION=restore ;;
    setdomain) ACTION=setdomain ;;
    menu)                          ACTION=mainmenu ;;
    menulock)                      ACTION=menu ;;
    setbot)                        ACTION=setbot ;;
    setunlock)                     ACTION=setunlock ;;
    *) show_help; exit 1 ;;
esac

command -v python3 >/dev/null 2>&1 || { print_error "python3 tidak ditemukan"; exit 1; }
load_conf
case "$ACTION" in
    setbot|setunlock|mainmenu|ssh_*|setdomain|backupmenu|backup_now|restore) ;;      # tidak wajib login Marzban
    *) login ;;
esac

case "$ACTION" in
    add)    cmd_add ;;
    renew)  cmd_renew ;;
    dell)   cmd_dell ;;
    trial)  cmd_trial ;;
    cek)    cmd_cek ;;
    lock)   cmd_lockunlock lock ;;
    unlock) cmd_lockunlock unlock ;;
    menu)   cmd_menulock ;;
    setbot)    cmd_setbot ;;
    setunlock) cmd_setunlock ;;
    mainmenu)  cmd_mainmenu ;;
    ssh_add)    cmd_ssh_add ;;
    ssh_renew)  cmd_ssh_renew ;;
    ssh_dell)   cmd_ssh_dell ;;
    ssh_trial)  cmd_ssh_trial ;;
    ssh_cek)    cmd_ssh_cek ;;
    ssh_lock)   cmd_ssh_lockunlock lock ;;
    ssh_unlock) cmd_ssh_lockunlock unlock ;;
    ssh_banner) cmd_ssh_banner ;;
    backupmenu) cmd_backupmenu ;;
    backup_now) cmd_backup_now ;;
    restore)    cmd_restore "$ARG1" ;;
    *)          mainmenu ;;
esac
