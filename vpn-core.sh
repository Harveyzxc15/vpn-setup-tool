#!/bin/zsh
# VPN 連線核心邏輯 — 此檔案由 GitHub 自動下發，所有人共用
# ⚠️ 新版安裝的 sudoers 只允許下面這幾種固定寫法，改 sudo 那幾行的參數會讓同事全部連不上：
#    sudo -n $OFV -c $HOME/.config/openfortivpn/config
#    sudo -n /usr/bin/pkill -f "openfortivpn -c"
#    sudo -n /usr/bin/pkill -9 -f "openfortivpn -c"
REPO_RAW="https://raw.githubusercontent.com/Harveyzxc15/vpn-setup-tool/main"
CFG="$HOME/.config/openfortivpn/config"
STOP_FLAG="/tmp/vpn-stop-$(whoami)"
STATUS_FILE="/tmp/vpn-status-$(whoami)"
LOG="$HOME/Library/Logs/vpn.log"
KC_SERVICE="vpn-setup-tool"
HEALTH_HOST="192.168.1.177"   # EPB 伺服器：連上後 ping 得到，之後連續 90 秒不通就判定通道卡死
DELAYS=(5 10 30 60)           # 連續斷線時的重連間隔（秒）
OFV="/opt/homebrew/bin/openfortivpn"
[ -x "$OFV" ] || OFV="/usr/local/bin/openfortivpn"

log() { print -r -- "$(date '+%F %T') $*" >> "$LOG"; }
notify() { osascript -e "display notification \"$2\" with title \"$1\" sound name \"Basso\"" 2>/dev/null; }
set_status() { print -r -- "$1" > "$STATUS_FILE"; }

# 單一實例保護：清掉舊的連線迴圈與殘留連線
for pid in $(pgrep -f "vpn-core.sh"); do
    [ "$pid" != "$$" ] && kill -9 "$pid" 2>/dev/null
done
sudo -n /usr/bin/pkill -f "openfortivpn -c" 2>/dev/null
sleep 2
sudo -n /usr/bin/pkill -9 -f "openfortivpn -c" 2>/dev/null

# 紀錄檔只留最近 1000 行
mkdir -p "${LOG:h}"
[ -f "$LOG" ] && tail -n 1000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
log "===== 開始連線 ====="
set_status connecting

# 同步本機小工具（啟動器、斷線、改密碼、狀態列…）：下載內容通過語法檢查才覆蓋
sync_file() {  # $1=repo 內路徑 $2=本機路徑
    local tmp; tmp=$(mktemp) || return
    if curl -sf --max-time 5 "$REPO_RAW/$1" -o "$tmp" \
        && [ "$(head -1 "$tmp")" = "#!/bin/zsh" ] && zsh -n "$tmp" 2>/dev/null; then
        if ! cmp -s "$tmp" "$2"; then
            mv "$tmp" "$2" && chmod 755 "$2" && log "已更新 $2"
            return
        fi
    fi
    rm -f "$tmp"
}
for f in vpn-connect.sh vpn-stop.sh vpn-passwd.sh vpn-account.sh vpn-auto.sh; do
    sync_file "scripts/$f" "$HOME/$f" &
done
PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
[ -d "$PLUGIN_DIR" ] && sync_file "scripts/vpn.10s.sh" "$PLUGIN_DIR/vpn.10s.sh" &
wait

# 憑證同步：必須是 64 碼十六進位才寫入（避免抓到錯誤頁面把設定檔寫壞）
LATEST_CERT=$(curl -sf --max-time 3 "$REPO_RAW/trusted-cert.txt" | tr -d '[:space:]')
if [[ "$LATEST_CERT" =~ ^[0-9a-f]{64}$ ]]; then
    sed -i '' "s/^trusted-cert = .*/trusted-cert = $LATEST_CERT/" "$CFG"
elif [ -n "$LATEST_CERT" ]; then
    log "憑證格式不對，沿用原本的：${LATEST_CERT[1,80]}"
fi

USER_NAME=$(sed -n 's/^username = //p' "$CFG")
get_password() { security find-generic-password -s "$KC_SERVICE" -a "$USER_NAME" -w 2>/dev/null; }

# 密碼從設定檔搬進鑰匙圈（本機的 vpn-passwd / vpn-account 已是鑰匙圈版才搬，避免舊工具改不到密碼）
OLD_PW=$(sed -n 's/^password = //p' "$CFG")
if [ -n "$OLD_PW" ] && grep -q "$KC_SERVICE" "$HOME/vpn-passwd.sh" 2>/dev/null \
    && grep -q "$KC_SERVICE" "$HOME/vpn-account.sh" 2>/dev/null; then
    if security add-generic-password -U -s "$KC_SERVICE" -a "$USER_NAME" -w "$OLD_PW" \
        && [ "$(get_password)" = "$OLD_PW" ]; then
        sed -i '' '/^password = /d' "$CFG"
        log "密碼已搬進鑰匙圈，設定檔不再存明文"
    fi
fi
unset OLD_PW

# 看門狗：通道卡死（例如睡眠喚醒後）就砍掉 openfortivpn，讓下面的迴圈重連
watchdog() {
    local seen=0 bad=0
    while sleep 30; do
        if ping -c1 -t3 "$HEALTH_HOST" >/dev/null 2>&1; then
            seen=1; bad=0
        elif (( seen )) && pgrep -x openfortivpn >/dev/null; then
            (( bad++ ))
            if (( bad >= 3 )); then
                log "內網 $HEALTH_HOST 連續 90 秒不通，強制重連"
                sudo -n /usr/bin/pkill -f "openfortivpn -c" 2>/dev/null
                seen=0; bad=0
            fi
        fi
    done
}
watchdog &
WD_PID=$!

rm -f "$STOP_FLAG"
trap 'kill $WD_PID 2>/dev/null' EXIT
trap 'rm -f "$STOP_FLAG" "$STATUS_FILE"; exit 0' INT TERM

fails=0
while true; do
    PW=$(get_password)
    if [ -z "$PW" ] && ! grep -q '^password = .' "$CFG"; then
        set_status need_password
        log "找不到密碼，停止"
        notify "VPN 沒有密碼" "請開終端機輸入 vpn-passwd 設定密碼"
        exit 1
    fi

    set_status connecting
    started=$SECONDS
    session=$(mktemp)
    print -r -- "$PW" | sudo -n "$OFV" -c "$CFG" 2>&1 | tee -a "$LOG" "$session"
    unset PW

    if [ -f "$STOP_FLAG" ]; then
        rm -f "$STOP_FLAG" "$STATUS_FILE" "$session"
        exit 0
    fi

    # 密碼錯／沒權限：重試只會讓帳號被鎖，直接停
    if grep -q "Could not authenticate to" "$session"; then
        rm -f "$session"
        set_status auth_failed
        log "帳號或密碼錯誤，停止重試"
        notify "VPN 密碼錯誤，已停止重試" "請開終端機輸入 vpn-passwd 更新密碼"
        exit 1
    fi
    if grep -q "a password is required" "$session"; then
        rm -f "$session"
        set_status sudo_failed
        log "sudo 免密碼規則不符，停止"
        notify "VPN 權限設定有問題" "請重新執行安裝指令"
        exit 1
    fi
    rm -f "$session"

    # 連上超過 2 分鐘才斷，視為一般斷線，重連間隔從頭算
    (( SECONDS - started > 120 )) && fails=0
    (( fails++ ))
    delay=${DELAYS[$(( fails < ${#DELAYS} ? fails : ${#DELAYS} ))]}
    set_status reconnecting
    log "已斷線，$delay 秒後重連（連續第 $fails 次）"
    notify "VPN 已斷線" "$delay 秒後自動重連..."
    sleep "$delay"
done
