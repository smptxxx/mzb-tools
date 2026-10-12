#!/bin/bash
# mzb-auto-update — cek versi repo GitHub vs local, prompt "Enter untuk update"
REPO="smptxxx/mzb-tools"
BRANCH="main"
LOCAL_DIR="/usr/local/bin"
VER_FILE="$LOCAL_DIR/.mzb-version"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

get_remote_ver() { curl -s -m 10 "$RAW/version.txt" 2>/dev/null | tr -d '[:space:]'; }
get_local_ver()  { [ -f "$VER_FILE" ] && cat "$VER_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0"; }

check() {
    local rv lv
    rv=$(get_remote_ver)
    lv=$(get_local_ver)
    [ -z "$rv" ] && return 1
    [ "$rv" != "$lv" ]
}

do_update() {
    local rv files f
    rv=$(get_remote_ver)
    echo "⬇  Mengunduh update v$rv…"
    mkdir -p /tmp/mzb-upd
    # daftar file: ambil dari files.txt di repo
    curl -s -m 15 "$RAW/files.txt" -o /tmp/mzb-upd/files.txt
    [ -s /tmp/mzb-upd/files.txt ] || { echo "✘ files.txt gak bisa diunduh"; return 1; }
    # backup dulu
    tar czf /root/mzb-backup-$(date +%s).tgz -C $LOCAL_DIR $(cat /tmp/mzb-upd/files.txt | tr '\n' ' ') 2>/dev/null
    while read -r f; do
        [ -z "$f" ] && continue
        curl -s -m 20 "$RAW/mzb-tools/$f" -o "$LOCAL_DIR/$f" && chmod +x "$LOCAL_DIR/$f"
    done < /tmp/mzb-upd/files.txt
    # core & launcher di root bin
    curl -s -m 20 "$RAW/mzb-tools-core.sh" -o "$LOCAL_DIR/mzb-tools-core.sh" && chmod +x "$LOCAL_DIR/mzb-tools-core.sh"
    curl -s -m 20 "$RAW/mzb-tools" -o "$LOCAL_DIR/mzb-tools" && chmod +x "$LOCAL_DIR/mzb-tools"
    echo "$rv" > "$VER_FILE"
    rm -rf /tmp/mzb-upd
    echo "✔ Update selesai → v$rv"
}

case "$1" in
    check) check && echo "UPDATE_TERSEDIA:$(get_remote_ver)" || echo "UP_TO_DATE" ;;
    run)   do_update ;;
    banner)
        # tampil di dalam menu: kalau update tersedia → prompt Enter
        if check; then
            rv=$(get_remote_ver)
            echo ""
            echo -e "\033[1;93m╔══════════════════════════════════════╗\033[0m"
            echo -e "\033[1;93m║  ⬆  UPDATE TERSEDIA  →  v$rv"
            echo -e "\033[1;93m╚══════════════════════════════════════╝\033[0m"
            read -rp "   Tekan ENTER untuk update, Ctrl+C batal… " _
            do_update
            echo ""
        fi
        ;;
    *) echo "Usage: mzb-update {check|run|banner}" ;;
esac
