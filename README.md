# tencent-docs-skill（腾讯文档 Agent Skill 增强版）

对腾讯文档（`docs.qq.com`）官方 Agent Skill 的功能完善与扩展，重点补齐长期缺失的 **原生收集表 `form-mcp`（22 个工具）** 接入、工作流规范、实测避坑指南与无逻辑接口场景下的 L1/L2 方案。

---

## 为什么做这个增强版？

原版 `tencent-docs` Skill 仅覆盖 4 个 MCP 服务（`tencent-docs` / `doc-mcp` / `sheet-mcp` / `slide-mcp`），在收集表场景只能用 `manage.create_file(file_type="form")` 创建空白收集表，无法增删改题目或统计结果。

经实测发现，腾讯文档官方已开放第 5 个 MCP 端点：
- **端点地址**：`https://docs.qq.com/api/v6/form/mcp`（`mcp-FormMcpServiceService`）
- **工具数量**：**22 个原生收集表工具**
- **鉴权方式**：**直接复用你现有的腾讯文档 MCP Token**，无需重新授权

接入后，你的 AI Agent 将拥有完整的 **5 大服务、共 524 个工具**：

| 服务名 | Endpoint | 工具数 | 能力覆盖 |
|---|---|---:|---|
| `tencent-docs` | `https://docs.qq.com/openapi/mcp` | 240 | 文件/空间管理、智能文档（MDX）、智能表格、脑图、流程图、OCR、网页剪藏 |
| `doc-mcp` | `https://docs.qq.com/api/v6/doc/mcp` | 87 | Word 文档精细排版与编辑 |
| `sheet-mcp` | `https://docs.qq.com/api/v6/sheet/mcp` | 83 | Excel 电子表格精细编辑 |
| `slide-mcp` | `https://docs.qq.com/api/v6/slide/mcp` | 92 | PPT 幻灯片精细编辑 |
| **`form-mcp`** | **`https://docs.qq.com/api/v6/form/mcp`** | **22** | **原生收集表创建、题目编辑、定时重复配置、结果概览、明细分页与交叉分析** |

---

## 快速开始

### 1. 一键补齐 `form-mcp`（复用已有 Token）

前提：你已经通过 `mcporter` 完成过腾讯文档基础 MCP 授权（`~/.mcporter/mcporter.json` 中已有 `tencent-docs` 或 `doc-mcp` 配置）。

- **Windows (PowerShell)**：
  ```powershell
  .\scripts\setup-form-mcp.ps1
  ```
- **macOS / Linux**：
  ```bash
  bash ./scripts/setup-form-mcp.sh
  ```

运行成功后应看到 `22 tools · HTTP https://docs.qq.com/api/v6/form/mcp`。

### 2. 安装 Skill 到你的 Agent

将本仓库的 `skills/tencent-docs/` 目录复制或合并到你的 Agent Skill 目录（例如 Claude Code / Cursor / Antigravity / Codex 的 `skills/tencent-docs/`）。

---

## 核心文档与内容

```text
tencent-docs-skill/
├── scripts/
│   ├── setup-form-mcp.ps1                     # Windows 一键注册 form-mcp
│   └── setup-form-mcp.sh                      # macOS / Linux 一键注册 form-mcp
├── skills/tencent-docs/
│   ├── SKILL.md                               # 增强版主入口（5 端点路由与核心规则）
│   ├── form/
│   │   ├── entry.md                           # 原生收集表工作流、510002 会员降级与 L1 方案
│   │   └── api_reference.md                   # 22 个 form-mcp 工具完整 API 参考
│   └── references/
│       ├── form_logic_rfc.md                  # 收集表条件显隐/跳转接口 L2 提案规范（RFC）
│       └── auth_and_endpoints.md              # 5 端点配置与鉴权说明
└── examples/
    └── competition_form.json                  # 实测通过的竞赛与奖状收集表 JSON 模板
```

---

## 实测避坑总结

1. **版本锁机制（`510001`）**：调用 `form_update_content` 前必须先调用 `form_get_context` 获取最新 `base_version`（`base_pos` + `base_revision`）。
2. **会员题型限制（`510002`）**：`QUESTION_TYPE_SEGMENTATION`（分节符）和 `QUESTION_TYPE_TABLE`（表格题，支持动态多行录入竞赛名与奖状附件）需要腾讯文档会员权益；非会员账号请自动降级为「选项内嵌提示 + 非必填附属题 + 图片/文件上传题」，或使用智能表格表单视图（`smartsheet.add_view(view_type="form")`）。
3. **条件显隐 / 跳转逻辑**：目前腾讯文档公开接口（`form-mcp` / OpenAPI / 企业微信）均未开放 `logic` 字段，详见 [`skills/tencent-docs/references/form_logic_rfc.md`](./skills/tencent-docs/references/form_logic_rfc.md)。

## License

[MIT](./LICENSE)
