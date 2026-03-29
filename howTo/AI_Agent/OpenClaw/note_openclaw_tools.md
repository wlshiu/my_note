openclaw tools [[Back](./note_openclaw.md#tools)]
---

##

+ 

```json
{
  tools: {
    exec: {
      pathPrepend: ["~/bin", "/opt/oss/bin"],
      host: "sandbox",
      security: "allowlist",
      ask: "on-miss",      
    },
  },
}
```
- Windows 
```
{
  tools: {
    exec: {
      pathPrepend: [
        "C:\\Program Files\\Docker\\Docker\\resources\\bin",
        "C:\\Users\\admin\\AppData\\Local\\Microsoft\\WinGet\\Links"
      ]
    }
  }
}
```


+ web tools

```json
{
  "tools": {
    "web": {
      "search": {
        "enabled": true,
        "apiKey": "YOUR_BRAVE_SEARCH_API_KEY"
      },
      "fetch": {
        "enabled": true
      }
    }
  }
}
```

# Reference

+ [OpenClaw Exec 工具詳解：在工作區執行 Shell 指令的完整指南-](https://www.aigcmkt.com/zh/ZBnmQmGO.html)
+ [OpenClaw 权限设置教程(2026)：exec、shell、危险操作限制](https://tbbbk.com/openclaw-permissions-exec-shell-dangerous-ops-guide-2026/)
+ [Exec Tool - OpenClaw online document](https://docs.openclaw.ai/tools/exec)

+ [使用 Exec Tool 在工作區執行 Shell 指令 | OpenClaw](https://open-claw.bot/docs/zh-tw/tools/exec/)
+ [指令執行工具與審批完全指南：安全機制、配置與故障排除 | Clawdbot 教程 | OpenCodeDocs](https://lzw.me/docs/opencodedocs/zh-tw/moltbot/moltbot/advanced/tools-exec/)
+ [openclaw-docker-cn-im/openclaw.json.example at main · justlovemaki/openclaw-docker-cn-im](https://github.com/justlovemaki/openclaw-docker-cn-im/blob/main/openclaw.json.example)

