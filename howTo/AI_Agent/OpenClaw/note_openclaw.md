note_openclaw
---

# Prerequisites

OpenClaw 基於 [Node.js](https://nodejs.org/zh-tw/download) 運行, 且部分組件(如本地模型支持)需要編譯環境

+ `Node.js 22` 或以上版本
    > 安裝後開啟 `PowerShell` 輸入 `node -v` 確認版本

+ Windows 11 開啟指令執行權限

    ```PowerShell
    # 使用管理者權限
    > Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

+ Local LLM module with [LM-Studio](https://lmstudio.ai/download)

    - LM-Studio enaables the local network feature
    
        ![lm_studio_local_net](./lm_studio_local_net.jpg)
    
    - Local server configuration in LM-Studio

        ![lm_studio_server](./lm_studio_server.jpg)


# Setup OpenClaw

+ OpenClaw 官方安裝腳本 (一鍵安裝)

    - Windows

        ```PowerShell
        > irm https://openclaw.ai/install.ps1 | iex
        ```
    - Linux

        ```shell
        $ curl -fsSL https://openclaw.ai/install.sh | bash
        ```

# Reference

+ [OpenClaw 安裝教學：打造你的個人 AI 助理（2026 更新）](https://vocus.cc/article/69a81841fd897800016d184d)
+ [Openclaw 本地安装 Windows 快速部署深度详细全程演示 超强爆火个人 AI 助理（原 clowdbot moltbot） - YouTube](https://www.youtube.com/watch?v=8DJfvK4QK5M)
+ [OpenClaw + LM Studio Tutorial: Free Local AI Setup (No OpenAI/Gemini/Claude) - YouTube](https://www.youtube.com/watch?v=Bn_hkXCwO-U)




