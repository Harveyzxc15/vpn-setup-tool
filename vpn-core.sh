#!/bin/zsh
# VPN 連線核心邏輯 — 此檔案由 GitHub 自動下發，所有人共用
CERT_URL="https://raw.githubusercontent.com/Harveyzxc15/vpn-setup-tool/main/trusted-cert.txt"
STOP_FLAG="/tmp/vpn-stop-$(whoami)"

LATEST_CERT=$(curl -sf --max-time 3 "$CERT_URL")
if [ -n "$LATEST_CERT" ]; then
    sed -i '' "s/^trusted-cert = .*/trusted-cert = $LATEST_CERT/" ~/.config/openfortivpn/config
fi

rm -f "$STOP_FLAG"
trap 'rm -f "$STOP_FLAG"; exit 0' INT TERM

while true; do
    sudo openfortivpn -c ~/.config/openfortivpn/config
    if [ -f "$STOP_FLAG" ]; then
        rm -f "$STOP_FLAG"
        exit 0
    fi
    osascript -e 'display notification "5 秒後自動重連..." with title "VPN 已斷線" sound name "Basso"'
    sleep 5
done
