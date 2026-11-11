#!/bin/zsh
# 改 VPN 帳號＋密碼（換帳號通常密碼也要換，一起問）；密碼存進 macOS 鑰匙圈
CFG="$HOME/.config/openfortivpn/config"
olduser=$(sed -n 's/^username = //p' "$CFG")
echo -n "請輸入新的 VPN 帳號（例：SA1234）: "
read newuser < /dev/tty
echo -n "請輸入新的 VPN 密碼（輸入時不會顯示字）: "
read -s newpass < /dev/tty
echo ""
if [ -z "$newuser" ] || [ -z "$newpass" ]; then
    echo "帳號或密碼沒有輸入，未變更"
    exit 1
fi
security add-generic-password -U -s vpn-setup-tool -a "$newuser" -w "$newpass" || exit 1
[ "$olduser" != "$newuser" ] && security delete-generic-password -s vpn-setup-tool -a "$olduser" >/dev/null 2>&1
sed -i '' "s/^username = .*/username = $newuser/" "$CFG"
sed -i '' '/^password = /d' "$CFG"
rm -f "/tmp/vpn-status-$(whoami)"
echo "帳號密碼已更新，輸入 vpn 測試連線"
