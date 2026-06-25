#!/bin/zsh

echo "=== 公司 VPN 設定工具 ==="

# 安裝 Homebrew
if ! command -v brew &> /dev/null; then
    echo "[1/4] 安裝 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "[1/4] Homebrew 已安裝，略過"
fi

# 安裝 openfortivpn
if ! command -v openfortivpn &> /dev/null; then
    echo "[2/4] 安裝 openfortivpn..."
    brew install openfortivpn
else
    echo "[2/4] openfortivpn 已安裝，略過"
fi

# 安裝 SwiftBar
if [ ! -d "/Applications/SwiftBar.app" ]; then
    echo "[3/4] 安裝 SwiftBar..."
    brew install --cask swiftbar
else
    echo "[3/4] SwiftBar 已安裝，略過"
fi

# 輸入帳號密碼
echo ""
echo -n "請輸入 VPN 帳號: "
read username
echo -n "請輸入 VPN 密碼: "
read -s password
echo ""

# 建立 VPN 設定檔
mkdir -p ~/.config/openfortivpn
cat > ~/.config/openfortivpn/config << CONF
host = 202.133.226.82
port = 10443
username = $username
password = $password
trusted-cert = 8f7862731eaa40a11098763f9f32f7706a411f7c1db241b7782bbac801b3aeb7
CONF
chmod 600 ~/.config/openfortivpn/config

# 設定 alias
if ! grep -q "alias vpn=" ~/.zshrc; then
    echo 'alias vpn="sudo openfortivpn -c ~/.config/openfortivpn/config"' >> ~/.zshrc
fi

# 設定免密碼 sudo
CURRENT_USER=$(whoami)
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /opt/homebrew/bin/openfortivpn" | sudo tee /etc/sudoers.d/openfortivpn > /dev/null
sudo sh -c "echo '$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/pkill' >> /etc/sudoers.d/openfortivpn"

# 建立 SwiftBar plugin
echo "[4/4] 設定 SwiftBar 狀態列..."
mkdir -p ~/Library/Application\ Support/SwiftBar/Plugins
cat > ~/Library/Application\ Support/SwiftBar/Plugins/vpn.10s.sh << 'PLUGIN'
#!/bin/zsh
if pgrep -x "openfortivpn" > /dev/null; then
    echo "VPN ● | color=#00aa00"
    echo "---"
    echo "狀態：已連線 ✓"
    echo "斷線 | bash=/usr/bin/sudo param1=pkill param2=-x param3=openfortivpn terminal=false refresh=true"
else
    echo "VPN ○ | color=#cc0000"
    echo "---"
    echo "狀態：未連線"
    echo "連線 | bash=/usr/bin/sudo param1=/opt/homebrew/bin/openfortivpn param2=-c param3=$HOME/.config/openfortivpn/config terminal=false refresh=true"
fi
PLUGIN
chmod +x ~/Library/Application\ Support/SwiftBar/Plugins/vpn.10s.sh

# 設定 SwiftBar plugin 路徑並啟動
defaults write com.ameba.SwiftBar PluginDirectory "$HOME/Library/Application Support/SwiftBar/Plugins"
open /Applications/SwiftBar.app

echo ""
echo "=== 設定完成！==="
echo "  - Terminal 輸入 'vpn' 可連線（需重開 Terminal）"
echo "  - 狀態列可直接點選連線/斷線"
