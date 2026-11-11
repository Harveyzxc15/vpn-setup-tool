#!/bin/zsh
# 改 VPN 密碼：存進 macOS 鑰匙圈（服務名 vpn-setup-tool），設定檔不存明文
CFG="$HOME/.config/openfortivpn/config"
user=$(sed -n 's/^username = //p' "$CFG")
echo -n "請輸入新的 VPN 密碼（輸入時不會顯示字）: "
read -s newpass < /dev/tty
echo ""
if [ -z "$newpass" ]; then
    echo "沒有輸入密碼，未變更"
    exit 1
fi
security add-generic-password -U -s vpn-setup-tool -a "$user" -w "$newpass" || exit 1
sed -i '' '/^password = /d' "$CFG"
rm -f "/tmp/vpn-status-$(whoami)"
echo "密碼已更新（存在鑰匙圈），輸入 vpn 測試連線"
