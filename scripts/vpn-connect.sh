#!/bin/zsh
# 啟動器：抓 GitHub 最新的 vpn-core.sh 來跑；抓到的內容通過檢查才覆蓋快取（離線就用快取）
REMOTE="https://raw.githubusercontent.com/Harveyzxc15/vpn-setup-tool/main/vpn-core.sh"
CACHE="$HOME/.vpn-core.sh"
TMP=$(mktemp)
if curl -sf --max-time 3 "$REMOTE" -o "$TMP" \
    && [ "$(head -1 "$TMP")" = "#!/bin/zsh" ] && zsh -n "$TMP" 2>/dev/null; then
    mv "$TMP" "$CACHE"
else
    rm -f "$TMP"
fi
if [ -f "$CACHE" ]; then
    exec zsh "$CACHE"
fi
echo "錯誤：無法取得連線腳本（沒有網路且無快取）"
exit 1
