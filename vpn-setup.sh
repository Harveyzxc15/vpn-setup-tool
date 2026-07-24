#!/bin/zsh

# 進度條：draw_bar 目前步驟 總步驟 說明
draw_bar() {
    local cur=$1 total=$2 label=$3
    local width=24
    local filled=$(( cur * width / total ))
    local bar="" i
    for (( i=0; i<width; i++ )); do
        if (( i < filled )); then bar+="█"; else bar+="░"; fi
    done
    local pct=$(( cur * 100 / total ))
    echo ""
    echo "  【${bar}】 ${pct}%  步驟 ${cur}/${total}｜${label}"
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        公司 VPN 一鍵設定工具              ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "共 6 個步驟，過程中會需要輸入兩種密碼："
echo "  🔑 VPN 帳號密碼（公司給的，SA 開頭）"
echo "  💻 Mac 開機密碼（你自己電腦的登入密碼）"
echo "什麼時候輸入哪一種，畫面都會提示，不用緊張。"
echo ""

# ── 前置檢查：命令列開發者工具（Homebrew 必需，新機常缺）──
if ! xcode-select -p &> /dev/null; then
    draw_bar 0 6 "安裝命令列開發者工具（Homebrew 需要）"
    echo "  這台 Mac 還沒有「命令列開發者工具」。"
    echo "  → 螢幕會跳出安裝視窗，請按「安裝」，然後回到這裡等它裝完。"
    xcode-select --install 2>/dev/null
    echo ""
    echo -n "  等待安裝完成中（裝好會自動繼續，請勿關閉視窗）"
    for i in {1..240}; do
        xcode-select -p &> /dev/null && break
        sleep 5
        printf "."
    done
    echo ""
    if ! xcode-select -p &> /dev/null; then
        echo ""
        echo "  ❌ 開發者工具仍未裝好。可能原因與解法："
        echo "     • 跳出「無法從軟體更新伺服器取得」→ 換手機熱點，或稍後重跑本指令"
        echo "     • 電腦版本較舊、App Store 抓不到 → 到 Apple 官網手動下載："
        echo "         https://developer.apple.com/download/all/"
        echo "         （登入 Apple ID → 搜尋 Command Line Tools → 下載對應版本安裝）"
        echo ""
        echo "  裝好後，重新執行本安裝指令即可。"
        exit 1
    fi
    echo "  ✓ 開發者工具已安裝"
fi

# Apple Silicon 與 Intel 的 Homebrew 路徑不同
if [ "$(uname -m)" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# 安裝 Homebrew
if ! command -v brew &> /dev/null; then
    draw_bar 1 6 "安裝 Homebrew（需要幾分鐘，請耐心等）"
    echo "┌─────────────────────────────────────────┐"
    echo "│ 💻 等一下如果出現 Password: 或按 RETURN   │"
    echo "│    請輸入你的「Mac 開機密碼」再按 Enter    │"
    echo "│    （輸入時畫面不會顯示字，是正常的）      │"
    echo "└─────────────────────────────────────────┘"
    echo "  ⏳ 這步會停在畫面上一段時間、沒有跑動的進度條，是正常的，請勿關閉視窗。"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> ~/.zshrc
    eval "$($BREW_PREFIX/bin/brew shellenv)"
else
    draw_bar 1 6 "Homebrew 已安裝 ✓"
fi

# 安裝 openfortivpn
if ! command -v openfortivpn &> /dev/null; then
    draw_bar 2 6 "安裝 VPN 連線程式（openfortivpn）..."
    brew install openfortivpn
else
    draw_bar 2 6 "VPN 連線程式已安裝 ✓"
fi

# 安裝 SwiftBar
if [ ! -d "/Applications/SwiftBar.app" ]; then
    draw_bar 3 6 "安裝狀態列工具（SwiftBar）..."
    brew install --cask swiftbar
else
    draw_bar 3 6 "狀態列工具已安裝 ✓"
fi

# 輸入帳號密碼（已有設定檔則可跳過）
if [ -f ~/.config/openfortivpn/config ]; then
    draw_bar 4 6 "偵測到既有設定，保留原帳號密碼 ✓（要改密碼可事後用 vpn-passwd）"
else
    draw_bar 4 6 "設定 VPN 帳號密碼"
    echo "┌─────────────────────────────────────────┐"
    echo "│ 🔑 現在輸入的是「VPN 帳號密碼」            │"
    echo "│    就是公司給你的那組（帳號 SA 開頭）      │"
    echo "└─────────────────────────────────────────┘"
    echo -n "請輸入 VPN 帳號（例：SA1234）: "
    read username < /dev/tty
    echo -n "請輸入 VPN 密碼（輸入時不會顯示字）: "
    read -s password < /dev/tty
    echo ""
    echo "帳號密碼已記下 ✓"

    CERT_URL="https://raw.githubusercontent.com/Harveyzxc15/vpn-setup-tool/main/trusted-cert.txt"
    LATEST_CERT=$(curl -sf "$CERT_URL")
    [ -z "$LATEST_CERT" ] && LATEST_CERT="8f7862731eaa40a11098763f9f32f7706a411f7c1db241b7782bbac801b3aeb7"

    mkdir -p ~/.config/openfortivpn
    cat > ~/.config/openfortivpn/config << CONF
host = 202.133.226.82
port = 10443
username = $username
password = $password
trusted-cert = $LATEST_CERT
CONF
    chmod 600 ~/.config/openfortivpn/config
fi

# 連線腳本：啟動器（每次執行自動抓 GitHub 最新版邏輯）
cat > ~/vpn-connect.sh << 'SCRIPT'
#!/bin/zsh
REMOTE="https://raw.githubusercontent.com/Harveyzxc15/vpn-setup-tool/main/vpn-core.sh"
CACHE="$HOME/.vpn-core.sh"
NEW=$(curl -sf --max-time 3 "$REMOTE")
if [ -n "$NEW" ]; then
    echo "$NEW" > "$CACHE"
fi
if [ -f "$CACHE" ]; then
    exec zsh "$CACHE"
fi
echo "錯誤：無法取得連線腳本（沒有網路且無快取）"
exit 1
SCRIPT
chmod +x ~/vpn-connect.sh

# 斷線腳本（連迴圈一起停，避免自動重連）
cat > ~/vpn-stop.sh << 'SCRIPT'
#!/bin/zsh
touch "/tmp/vpn-stop-$(whoami)"
pgrep -f "vpn-core.sh" | xargs kill -9 2>/dev/null
sudo /usr/bin/pkill -f "openfortivpn -c" 2>/dev/null
sleep 2
sudo /usr/bin/pkill -9 -f "openfortivpn -c" 2>/dev/null
rm -f "/tmp/vpn-stop-$(whoami)"
exit 0
SCRIPT
chmod +x ~/vpn-stop.sh

# 改密碼腳本
cat > ~/vpn-passwd.sh << 'SCRIPT'
#!/bin/zsh
echo -n "請輸入新的 VPN 密碼: "
read -s newpass < /dev/tty
echo ""
escaped=$(printf '%s' "$newpass" | sed 's/[&/\\]/\\&/g')
sed -i '' "s/^password = .*/password = $escaped/" ~/.config/openfortivpn/config
echo "密碼已更新，輸入 vpn 測試連線"
SCRIPT
chmod +x ~/vpn-passwd.sh

# 改帳號腳本（換帳號通常密碼也要換，一起問）
cat > ~/vpn-account.sh << 'SCRIPT'
#!/bin/zsh
echo -n "請輸入新的 VPN 帳號（例：SA1234）: "
read newuser < /dev/tty
echo -n "請輸入新的 VPN 密碼（輸入時不會顯示字）: "
read -s newpass < /dev/tty
echo ""
sed -i '' "s/^username = .*/username = $newuser/" ~/.config/openfortivpn/config
escaped=$(printf '%s' "$newpass" | sed 's/[&/\\]/\\&/g')
sed -i '' "s/^password = .*/password = $escaped/" ~/.config/openfortivpn/config
echo "帳號密碼已更新，輸入 vpn 測試連線"
SCRIPT
chmod +x ~/vpn-account.sh

# 設定 alias
if grep -q "alias vpn=" ~/.zshrc; then
    sed -i '' 's|alias vpn=.*|alias vpn="zsh ~/vpn-connect.sh"|' ~/.zshrc
else
    echo 'alias vpn="zsh ~/vpn-connect.sh"' >> ~/.zshrc
fi
grep -q "alias vpn-passwd=" ~/.zshrc || echo 'alias vpn-passwd="zsh ~/vpn-passwd.sh"' >> ~/.zshrc
grep -q "alias vpn-account=" ~/.zshrc || echo 'alias vpn-account="zsh ~/vpn-account.sh"' >> ~/.zshrc

# 設定免密碼 sudo
draw_bar 5 6 "設定系統權限（之後連 VPN 就不用再打密碼）"
echo "┌─────────────────────────────────────────┐"
echo "│ 💻 等一下出現 Password: 時                │"
echo "│    請輸入你的「Mac 開機密碼」再按 Enter    │"
echo "│    （不是 VPN 密碼！輸入時不會顯示字）     │"
echo "└─────────────────────────────────────────┘"
CURRENT_USER=$(whoami)
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: $BREW_PREFIX/bin/openfortivpn" | sudo tee /etc/sudoers.d/openfortivpn > /dev/null
sudo sh -c "echo '$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/pkill' >> /etc/sudoers.d/openfortivpn"

# SwiftBar plugin
draw_bar 6 6 "設定狀態列圖示..."
mkdir -p ~/Library/Application\ Support/SwiftBar/Plugins
cat > ~/Library/Application\ Support/SwiftBar/Plugins/vpn.10s.sh << 'PLUGIN'
#!/bin/zsh
if pgrep -x "openfortivpn" > /dev/null; then
    echo "VPN ● | color=#00aa00"
    echo "---"
    echo "狀態：已連線 ✓"
    echo "斷線 | bash=/bin/zsh param1=$HOME/vpn-stop.sh terminal=false refresh=true"
else
    echo "VPN ○ | color=#cc0000"
    echo "---"
    echo "狀態：未連線"
    echo "連線 | bash=/bin/zsh param1=$HOME/vpn-connect.sh terminal=false refresh=true"
fi
PLUGIN
chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/vpn.10s.sh

defaults write com.ameba.SwiftBar PluginDirectory "$HOME/Library/Application Support/SwiftBar/Plugins"
open /Applications/SwiftBar.app

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        ✅ 全部 6 個步驟完成！              ║"
echo "╚══════════════════════════════════════════╝"
echo "  - vpn         連線（斷線自動重連 + 通知）"
echo "  - vpn-passwd  更改 VPN 密碼"
echo "  - vpn-account 更改 VPN 帳號＋密碼"
echo "  - 狀態列可點選連線/斷線"
echo "  - 憑證自動從網路同步，不需手動更新"
