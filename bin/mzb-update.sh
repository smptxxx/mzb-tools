#!/bin/bash
# mzb-auto-update v4 — jsDelivr CDN (no rate limit, no cache issue)
REPO="smptxxx/mzb-tools"
BRANCH="main"
LOCAL_DIR="/usr/local/bin"
VER_FILE="$LOCAL_DIR/.mzb-version"
CDN="https://cdn.jsdelivr.net/gh/$REPO@$BRANCH"

get_remote_ver() { curl -s -m 10 "$CDN/version.txt" | tr -d '[:space:]'; }
get_local_ver()  { [ -f "$VER_FILE" ] && cat "$VER_FILE" | tr -d '[:space:]' || echo "0"; }
check() {
    local rv lv; rv=$(get_remote_ver); lv=$(get_local_ver)
    [ -z "$rv" ] && return 1
    [ "$rv" != "$lv" ]
}

do_update() {
    local rv; rv=$(get_remote_ver)
    [ -z "$rv" ] && { echo "✘ gak bisa cek versi (CDN takedown?)"; return 1; }
    echo "⬇  Download update v$rv…"
    mkdir -p /tmp/mzb-upd
    curl -s -m 20 "$CDN/files.txt" -o /tmp/mzb-upd/files.txt
    [ -s /tmp/mzb-upd/files.txt ] || { echo "✘ files.txt gagal"; return 1; }
    # backup dulu (semua file + core + launcher)
    local flist; flist=$(tr '\n' ' ' < /tmp/mzb-upd/files.txt)
    tar czf "/root/mzb-backup-$(date +%s).tgz" -C $LOCAL_DIR $flist mzb-tools-core.sh mzb-tools 2>/dev/null
    local fail=0
    while read -r f; do
        [ -z "$f" ] && continue
        curl -s -m 20 "$CDN/mzb-tools/$f" -o "$LOCAL_DIR/$f" && chmod +x "$LOCAL_DIR/$f" || { echo "✘ $f"; fail=1; }
    done < /tmp/mzb-upd/files.txt
    curl -s -m 30 "$CDN/mzb-tools/mzb-tools-core.sh" -o "$LOCAL_DIR/mzb-tools-core.sh" \
        && chmod +x "$LOCAL_DIR/mzb-tools-core.sh" || { echo "✘ core.sh"; fail=1; }
    curl -s -m 20 "$CDN/mzb-tools/mzb-tools" -o "$LOCAL_DIR/mzb-tools" && chmod +x "$LOCAL_DIR/mzb-tools"
    # sanity
    if [ ! -s "$LOCAL_DIR/mzb-tools-core.sh" ]; then
        echo "✘ core.sh kosong — rollback"
        local bk; bk=$(ls -t /root/mzb-backup-*.tgz 2>/dev/null | head -1)
        [ -n "$bk" ] && tar xzOf "$bk" mzb-tools-core.sh > "$LOCAL_DIR/mzb-tools-core.sh" 2>/dev/null
        return 1
    fi
    echo "$rv" > "$VER_FILE"
    rm -rf /tmp/mzb-upd
    [ $fail -eq 0 ] && echo "✔ Update selesai → v$rv" || echo "⚠ selesai dengan beberapa gagal"
    echo "   (backup lama: /root/mzb-backup-*.tgz)"
}

case "$1" in
    check) check && echo "UPDATE_TERSEDIA:$(get_remote_ver)" || echo "UP_TO_DATE" ;;
    run)   do_update ;;
    banner)
        if check; then
            rv=$(get_remote_ver)
            echo ""
            echo -e "\033[1;93m╔══════════════════════════════════════════╗\033[0m"
            echo -e "\033[1;93m║   ⬆  UPDATE TERSEDIA  →  v$rv"
            echo -e "\033[1;93m╚══════════════════════════════════════════╝\033[0m"
            read -rp "   Tekan ENTER untuk update, Ctrl+C batal… " _
            do_update
            echo ""
        fi
        ;;
    force) echo "0" > "$VER_FILE"; do_update ;;
    *) echo "Usage: mzb-update {check|run|banner|force}" ;;
esac
