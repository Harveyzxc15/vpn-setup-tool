#!/bin/zsh
# SwiftBar 狀態列：綠＝通道有 IP、黃＝連線／重連中、紅＝未連線
ME=$(whoami)
STATUS=$(cat "/tmp/vpn-status-$ME" 2>/dev/null)
IP=$(ifconfig 2>/dev/null | awk '/^ppp[0-9]+:/{p=1;next} /^[a-z]/{p=0} p&&/inet /{print $2;exit}')
AUTO="$HOME/Library/LaunchAgents/com.vpn-setup-tool.autoconnect.plist"
STOP="斷線 | bash=/bin/zsh param1=$HOME/vpn-stop.sh terminal=false refresh=true"
CONNECT="連線 | bash=/bin/zsh param1=$HOME/vpn-connect.sh terminal=false refresh=true"

if pgrep -x openfortivpn > /dev/null && [ -n "$IP" ]; then
    echo "VPN | color=#00aa00"
    echo "---"
    echo "狀態：已連線 ✓"
    echo "IP：$IP"
    echo "$STOP"
elif pgrep -f "vpn-core.sh" > /dev/null; then
    echo "VPN | color=#d99a00"
    echo "---"
    echo "狀態：連線中／重連中…"
    echo "$STOP"
else
    echo "VPN | color=#cc0000"
    echo "---"
    case "$STATUS" in
        auth_failed)   echo "狀態：密碼錯誤，已停止重試"; echo "請開終端機輸入 vpn-passwd" ;;
        need_password) echo "狀態：還沒設定密碼"; echo "請開終端機輸入 vpn-passwd" ;;
        sudo_failed)   echo "狀態：權限設定有問題"; echo "請重新執行安裝指令" ;;
        *)             echo "狀態：未連線" ;;
    esac
    echo "$CONNECT"
fi
echo "---"
if [ -f "$AUTO" ]; then
    echo "開機自動連線：開 ✓ | bash=/bin/zsh param1=$HOME/vpn-auto.sh param2=off terminal=false refresh=true"
else
    echo "開機自動連線：關 | bash=/bin/zsh param1=$HOME/vpn-auto.sh param2=on terminal=false refresh=true"
fi
echo "查看連線紀錄 | bash=/usr/bin/open param1=-a param2=Console param3=$HOME/Library/Logs/vpn.log terminal=false"
