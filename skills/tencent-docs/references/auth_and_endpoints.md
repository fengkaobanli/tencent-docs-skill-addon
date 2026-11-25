# 腾讯文档 5 大官方 MCP 端点与鉴权说明

腾讯文档个人版（`docs.qq.com`）的 MCP 能力分布在 5 个独立端点上，**共用同一个 Token**：

```json
{
  "mcpServers": {
    "tencent-docs": {
      "baseUrl": "https://docs.qq.com/openapi/mcp",
      "headers": { "Authorization": "<YOUR_TENCENT_DOCS_TOKEN>" }
    },
    "doc-mcp": {
      "baseUrl": "https://docs.qq.com/api/v6/doc/mcp",
      "headers": { "Authorization": "<YOUR_TENCENT_DOCS_TOKEN>" }
    },
    "sheet-mcp": {
      "baseUrl": "https://docs.qq.com/api/v6/sheet/mcp",
      "headers": { "Authorization": "<YOUR_TENCENT_DOCS_TOKEN>" }
    },
    "slide-mcp": {
      "baseUrl": "https://docs.qq.com/api/v6/slide/mcp",
      "headers": { "Authorization": "<YOUR_TENCENT_DOCS_TOKEN>" }
    },
    "form-mcp": {
      "baseUrl": "https://docs.qq.com/api/v6/form/mcp",
      "headers": { "Authorization": "<YOUR_TENCENT_DOCS_TOKEN>" }
    }
  }
}
```

## 获取与验证方式

1. **获取 Token**：登录腾讯文档开放授权页面（如 `https://docs.qq.com/scenario/open-claw.html?nlc=1`）获取个人版 MCP Token。
2. **快速补齐 `form-mcp`**：如果你已通过官方脚本配置好 `tencent-docs` / `doc-mcp` 等服务，运行本仓库的 `scripts/setup-form-mcp.ps1`（Windows）或 `scripts/setup-form-mcp.sh`（macOS/Linux），会自动从现有配置中复用 `headers` 注册 `form-mcp`。
3. **验证连接**：
   ```bash
   mcporter list form-mcp
   ```
   正常应输出 `22 tools · HTTP https://docs.qq.com/api/v6/form/mcp`。
