#!/bin/zsh
# 斷線（連迴圈一起停，避免自動重連）
touch "/tmp/vpn-stop-$(whoami)"
pgrep -f "vpn-core.sh" | xargs kill -9 2>/dev/null
sudo -n /usr/bin/pkill -f "openfortivpn -c" 2>/dev/null
sleep 2
sudo -n /usr/bin/pkill -9 -f "openfortivpn -c" 2>/dev/null
rm -f "/tmp/vpn-stop-$(whoami)" "/tmp/vpn-status-$(whoami)"
print -r -- "$(date '+%F %T') 手動斷線" >> "$HOME/Library/Logs/vpn.log"
exit 0
