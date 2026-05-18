# 公司 VPN 一鍵設定工具

## 簡介

本工具用於在 macOS 上快速設定公司 VPN 連線，取代 FortiClient 需手動輸入密碼的不便。設定完成後可透過終端機指令或狀態列圖示一鍵連線。

---

## 系統需求

| 項目 | 需求 |
|------|------|
| 作業系統 | macOS 12 Monterey 以上 |
| 晶片 | Apple Silicon (M1/M2/M3) 或 Intel |
| 網路 | 一般網路連線即可 |

---

## 安裝步驟

### 1. 取得安裝腳本

將 `vpn-setup.sh` 檔案存放至任意位置（建議放在下載資料夾）。

### 2. 執行安裝

打開 Terminal（終端機），執行：

```bash
zsh ~/Downloads/vpn-setup.sh
```

### 3. 輸入帳號密碼

腳本執行過程中會詢問：
- **VPN 帳號**：輸入個人帳號（例如：SA1469）
- **VPN 密碼**：輸入個人密碼（輸入時畫面不顯示字元，屬正常現象）

### 4. 完成

腳本自動完成所有設定，重開 Terminal 即可使用。

---

## 使用方式

### 方式一：狀態列圖示（推薦）

安裝完成後，Mac 右上角狀態列會出現 VPN 圖示：

- **VPN ●**（綠色）：已連線
- **VPN ○**（紅色）：未連線

點擊圖示可選擇「連線」或「斷線」，每 10 秒自動更新狀態。

### 方式二：Terminal 指令

重開 Terminal 後輸入：

```bash
vpn
```

按 `Control + C` 可斷線。

---

## 腳本自動安裝項目

| 項目 | 說明 |
|------|------|
| Homebrew | macOS 套件管理工具 |
| openfortivpn | 開源 FortiGate VPN 客戶端 |
| SwiftBar | 狀態列顯示工具 |

---

## 安全性說明

- VPN 密碼儲存於 `~/.config/openfortivpn/config`，權限設為 `600`，僅本人可讀取
- sudo 免密碼設定僅限 `openfortivpn` 與 `pkill` 指令，範圍最小化

---

## 常見問題

**Q：安裝後狀態列沒有出現圖示？**
執行以下指令重啟 SwiftBar：
```bash
killall SwiftBar; open /Applications/SwiftBar.app
```

**Q：點選連線後沒有反應？**
改用 Terminal 輸入 `vpn` 確認是否可以連線。

**Q：VPN 密碼更改後怎麼更新？**
執行以下指令重新編輯設定檔：
```bash
nano ~/.config/openfortivpn/config
```
修改 `password =` 那行後按 `Ctrl + O` 儲存，`Ctrl + X` 離開。

---

## VPN 伺服器資訊

| 項目 | 值 |
|------|----|
| 伺服器 | 202.133.226.82 |
| Port | 10443 |
| 類型 | SSL-VPN (FortiGate) |

