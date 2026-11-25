# tencent-docs-skill-addon（非官方社区附加扩展）

> **⚠️ 免责声明 / Disclaimer（非官方项目）**
>
> 1. **非官方身份**：本项目为个人/社区维护的**非官方第三方附加扩展（Unofficial Community Add-on）**，与腾讯公司（Tencent）及腾讯文档官方团队无任何隶属、授权、合作或官方背书关系。
> 2. **商标与知识产权**：「腾讯文档」「Tencent Docs」及相关产品名称、商标与服务端接口版权均归腾讯公司所有。
> 3. **合规使用**：本项目仅提供基于 MCP 协议的客户端配置辅助脚本、工作流文档与开源社区提案，**不内置、不收集、不绕过任何账号凭据、鉴权机制或会员权益**。使用前请通过腾讯文档正规渠道自行完成授权，并严格遵守《腾讯文档软件许可及服务协议》及相关法律法规。
> 4. **责任限制**：因接口变更、配置错误或违规使用导致的任何数据损失或风险，由使用者自行承担，本项目作者不承担任何直接或间接责任。

---

## 项目简介

这是一个面向 AI Agent 的**第三方附加 Skill 扩展包**，用于补全社区现有腾讯文档 MCP Skill 中缺失的 **收集表（`form-mcp`，22 个工具）** 接入说明、实测避坑指南与无逻辑接口场景下的 L1/L2 方案。

### 补齐了什么？

常见的腾讯文档 MCP Skill 配置通常只包含 4 个服务端点（`tencent-docs` / `doc-mcp` / `sheet-mcp` / `slide-mcp`），收集表场景往往只能创建空白文件。

经实测，`https://docs.qq.com/api/v6/form/mcp` 已提供 22 个原生收集表 MCP 工具，且可直接复用你本机已授权的腾讯文档 MCP Token：

| 服务名 | Endpoint | 工具数 | 能力覆盖 |
|---|---|---:|---|
| `tencent-docs` | `https://docs.qq.com/openapi/mcp` | 240 | 文件/空间管理、智能文档（MDX）、智能表格、脑图、流程图、OCR、网页剪藏 |
| `doc-mcp` | `https://docs.qq.com/api/v6/doc/mcp` | 87 | Word 文档精细排版与编辑 |
| `sheet-mcp` | `https://docs.qq.com/api/v6/sheet/mcp` | 83 | Excel 电子表格精细编辑 |
| `slide-mcp` | `https://docs.qq.com/api/v6/slide/mcp` | 92 | PPT 幻灯片精细编辑 |
| **`form-mcp`** | **`https://docs.qq.com/api/v6/form/mcp`** | **22** | **原生收集表创建、题目编辑、定时重复配置、结果概览、明细分页与交叉分析** |

---

## 快速开始

### 1. 一键补齐 `form-mcp`（复用你本机已有 Token）

前提：你已通过正规渠道完成 `mcporter` 的基础配置（`~/.mcporter/mcporter.json` 中已有 `tencent-docs` 或 `doc-mcp`）。

- **Windows (PowerShell)**：
  ```powershell
  .\scripts\setup-form-mcp.ps1
  ```
- **macOS / Linux**：
  ```bash
  bash ./scripts/setup-form-mcp.sh
  ```

运行成功后应看到 `22 tools · HTTP https://docs.qq.com/api/v6/form/mcp`。

### 2. 安装附加 Skill

将本仓库的 `skills/tencent-docs/` 目录复制或合并到你的 Agent Skill 目录（例如 Claude Code / Cursor / Antigravity / Codex 对应的 skills 目录）。

---

## 目录结构

```text
tencent-docs-skill-addon/
├── scripts/
│   ├── setup-form-mcp.ps1                     # Windows 一键注册 form-mcp
│   └── setup-form-mcp.sh                      # macOS / Linux 一键注册 form-mcp
├── skills/tencent-docs/
│   ├── SKILL.md                               # 附加版主入口（5 端点路由与核心规则）
│   ├── form/
│   │   ├── entry.md                           # 原生收集表工作流、510002 会员降级与 L1 方案
│   │   └── api_reference.md                   # 22 个 form-mcp 工具分类参考
│   └── references/
│       ├── form_logic_rfc.md                  # 收集表条件显隐/跳转接口 L2 社区提案（RFC）
│       └── auth_and_endpoints.md              # 5 端点配置与鉴权说明
└── examples/
    └── competition_form.json                  # 实测通过的竞赛与奖状收集表 JSON 模板
```

---

## 实测避坑总结

1. **版本锁机制（`510001`）**：调用 `form_update_content` 前必须先调用 `form_get_context` 获取最新 `base_version`（`base_pos` + `base_revision`）。
2. **会员题型限制（`510002`）**：`QUESTION_TYPE_SEGMENTATION`（分节符）和 `QUESTION_TYPE_TABLE`（表格题，支持动态多行录入竞赛名与奖状附件）需要腾讯文档会员权益；非会员账号请自动降级为「选项内嵌提示 + 非必填附属题 + 图片/文件上传题」，或使用智能表格表单视图（`smartsheet.add_view(view_type="form")`）。
3. **条件显隐 / 跳转逻辑**：目前公开 MCP 接口均未开放 `logic` 字段，详见社区 RFC 提案 [`skills/tencent-docs/references/form_logic_rfc.md`](./skills/tencent-docs/references/form_logic_rfc.md)。

## License

[MIT](./LICENSE)
