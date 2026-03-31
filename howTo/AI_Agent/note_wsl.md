Windows 11 WSL
---

# Install Ubuntu with windows WSL

Execute `PowerShell` with **Admin permission**

> 如果安裝程序在 0.0%時停止回應, 請加上 `--web-download` 選項

```
PS > wsl --install --web-download -d Ubuntu
```

### Check the status

```
PS > wsl --version
    WSL 版本： 2.6.3.0
    核心版本： 6.6.87.2-1
    WSLg 版本： 1.0.71
    MSRDC 版本： 1.2.6353
    Direct3D 版本： 1.611.1-81528511
    DXCore 版本： 10.0.26100.1-240331-1435.ge-release
    Windows 版本： 10.0.22631.3880

```

## Start Ubuntu

Execute `PowerShell` with **Admin permission**

```
PS > wsl
```

首次啟動 Ubuntu 時, 系統會提示創建 UNIX 使用者名和密碼

```
Installing, this may take a few minutes...
Please create a default UNIX user account. The username and password must not match your Windows username.
New UNIX username: xxx
New password:
Retype password:
```

## Shutdown Ubuntu (clearly)

```powershell
PS > wsl --shutdown
```

## Change the URL of packages source list 

```
$ lsb_release -a
    No LSB modules are available.
    Distributor ID: Ubuntu
    Description:    Ubuntu 24.04.4 LTS
    Release:        24.04
    Codename:       noble
    
$ sudo vi /etc/apt/sources.list.d/ubuntu.sources
    change http://... to https://...
```

## VM 配置文件

> 新建或編輯 `C:\Users\<user-name>\.wslconfig`

```ini
[wsl2]
# 啟用鏡像網絡模式 - 這是最重要的配置
networkingMode=mirrored

# 啟用 DNS 隧道, 防止 VPN 環境下域名解析失效
dnsTunneling=true

# 強制 WSL 使用 Windows 的 HTTP 代理設置
autoProxy=true

# 啟用集成防火墻支持
firewall=true

[experimental]
# 自動回收閒置內存, 優化性能
autoMemoryReclaim=gradual

# 支持主機回環地址訪問
hostAddressLoopback=true
```

# Network Configration

## Firewall

Execute `PowerShell` with **Admin permission**

```powershell
# 創建入站防火墻規則, 允許 OpenClaw 服務端口
New-NetFirewallRule -DisplayName "OpenClaw-Service" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 18789

# 驗證規則是否創建成功
Get-NetFirewallRule -DisplayName "OpenClaw-Service" | Format-Table
```


## WSL 2 網路架構原理

WSL2 採用輕量級虛擬機技術, 運行完整的 Linux 內核. 在網路層面, WSL2 有兩種主要模式:

### NAT 模式 (預設)

在預設的 NAT(網路位址轉換)模式下, WSL2 虛擬機擁有獨立的虛擬網路介面

```
┌─────────────────────────────────────────────────────┐
│                      Windows 主機                    │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │              WSL 2 虛擬機 (NAT)              │    │
│  │                                             │    │
│  │    eth0: 172.23.64.x (獨立虛擬子網)          │    │
│  │    Gateway: 172.23.64.1                     │    │
│  │    DNS: 172.23.64.1                         │    │
│  └─────────────────────────────────────────────┘    │
│              │                    │                 │
│              ▼                    ▼                 │
│    ┌─────────────────┐   ┌─────────────────┐        │
│    │ 虛擬交換機       │   │   Windows       │        │
│    │ (Hyper-V)       │   │   網路是配器     │        │
│    └─────────────────┘   └─────────────────┘        │
│              │                                      │
│              ▼                                      │
│    ┌─────────────────────────────────────────────┐  |
│    │            物理網路 / Internet               │  |
│    └─────────────────────────────────────────────┘  |
```                                            

+ NAT 模式特點
    - WSL2 擁有獨立的 IP 位址(172.x.x.x 範圍)
    - 外部網路無法直接訪問 WSL2
    - 需要埠轉發, 才能實現局域網訪問
    - VPN 相容性較差, 經常出現 DNS 解析問題

### 鏡像 (Mirrored) 模式 (推薦)

鏡像模式通過, 直接將 Windows 宿主機的網路介面狀態, 同步到 Linux 內核中, 消除了虛擬子網帶來的複雜性

```
┌───────────────────────────────────────────────────┐
│                      Windows 主機                 │
│                                                   │
│  ┌───────────────────────────────────────────┐    │
│  │              WSL 2 虛擬機 (mirrored)       │   │
│  │                                           │    │
│  │    eth0: 與 Host 共享相同區網 IP            │   │
│  │    植基暴露在 Windows 防火牆中              │   │
│  └───────────────────────────────────────────┘    │
│              │                                    │
│              │  (網路接口直接同步)                  │
│              ▼                                    │
│    ┌───────────────────────────────────────────┐  |
│    │            物理網路 / Internet             │  |
│    └───────────────────────────────────────────┘  |
```

+ Mirrored 模式特點

    - 與 Host 共用相同的區網 IP
    - 原生 IPv6 支援
    - VPN 相容性顯著提升
    - 區網內其他設備可直接發現
    - 防火牆規則直接作用於 WSL 應用
    
    
    
    
### 鏡像模式技術優勢對比

| 維度            | NAT 模式 (預設)        | 鏡像模式 (推薦) |
|------           |----------------       |----------------|
| IP 位址一致性    | 獨立虛擬 IP(172.x.x.x) | 與宿主機共用相同局域網 IP |
| IPv6 支援       | 極其有限                | 全面原生支援 |
| localhost 行為  | 跨平臺迴環複雜           | 原生雙向迴環支援 |
| VPN 兼容性      | 經常導致 DNS 丟包        | 顯著提升相容性 |
| 局域網可見性     | 需要手動埠轉發          | 局域網內其他設備可直接發現 |
| 防火牆控制      | 獨立規則                 | 直接使用 Windows 防火牆 |
| 埠轉發          | 需要手動配置             | 無需配置 |
    
# Reference 

+ [wsl-installation - Github](https://github.com/spoto-team/openclaw-wsl-guide/blob/main/wsl-installation.md)
+ [如何使用 WSL 在 Windows 上安裝 Linux](https://learn.microsoft.com/zh-tw/windows/wsl/install)



