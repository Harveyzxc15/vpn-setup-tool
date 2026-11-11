#!/bin/zsh
# 開機（登入）自動連線開關：vpn-auto.sh on | off
# 只寫入／移除 LaunchAgent，下次登入才生效，不會打斷目前的連線
LABEL="com.vpn-setup-tool.autoconnect"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
case "$1" in
on)
    mkdir -p "${PLIST:h}"
    cat > "$PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array><string>/bin/zsh</string><string>$HOME/vpn-connect.sh</string></array>
    <key>RunAtLoad</key><true/>
    <key>StandardOutPath</key><string>/dev/null</string>
    <key>StandardErrorPath</key><string>/dev/null</string>
</dict>
</plist>
PLISTEOF
    echo "已開啟：下次登入 Mac 會自動連 VPN"
    ;;
off)
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
    rm -f "$PLIST"
    echo "已關閉開機自動連線"
    ;;
*)
    echo "用法：vpn-auto.sh on | off"
    exit 1
    ;;
esac
