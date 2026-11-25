---
name: tencent-docs-addon
description: 非官方社区附加版腾讯文档（docs.qq.com）Agent Skill —— 补齐 5 个 MCP 端点（含 form-mcp 22 个收集表工具）的路由、工作流、会员题型降级与无逻辑接口 L1 收敛方案。本 Skill 为第三方非官方扩展，与腾讯无隶属关系。
homepage: https://github.com/fengkaobanli/tencent-docs-skill-addon
version: 1.1.0-community-addon
---

# 腾讯文档 MCP 社区附加使用指南（Unofficial Add-on）

> **免责声明**：本 Skill 为第三方社区维护的**非官方附加扩展**，与腾讯公司及腾讯文档官方无任何隶属、授权或背书关系。请通过腾讯文档正规途径获取个人授权并遵守平台服务协议。

本 Skill 在社区常见配置基础上，补齐了 **收集表 `form-mcp`（22 个工具）** 的接入指南、工作流规范、会员权益降级策略以及无逻辑接口场景下的 L1/L2 方案。

## 5 大 MCP 端点总览（共用同一授权 Token）

| 服务名 (`service`) | 官方 Endpoint | 工具数 | 负责品类与能力 |
|---|---|---:|---|
| `tencent-docs` | `https://docs.qq.com/openapi/mcp` | 240 | 通用文件/空间管理、智能文档（MDX）、智能表格（SmartSheet）、思维导图、流程图、OCR、网页剪藏 |
| `doc-mcp` | `https://docs.qq.com/api/v6/doc/mcp` | 87 | Word 文档精细编辑（段落/表格/样式/页眉页脚/目录/批注） |
| `sheet-mcp` | `https://docs.qq.com/api/v6/sheet/mcp` | 83 | Excel 电子表格精细编辑（单元格/公式/筛选/图表/条件格式） |
| `slide-mcp` | `https://docs.qq.com/api/v6/slide/mcp` | 92 | PPT 幻灯片精细编辑（页面/形状/表格/图表/动画/母版） |
| **`form-mcp`** | **`https://docs.qq.com/api/v6/form/mcp`** | **22** | **原生收集表全生命周期（普通/问卷/投票/文件收集/接龙/打卡的创建、题目编辑、周期配置、结果统计与交叉分析）** |

> 首次接入 `form-mcp` 时，运行仓库根目录下的 `scripts/setup-form-mcp.ps1`（Windows）或 `scripts/setup-form-mcp.sh`（macOS / Linux），即可自动复用现有 `mcporter` 中的腾讯文档 Token 注册 `form-mcp`。

---

## 场景路由表

| 用户意图 / 关键词 | 目标品类 | 首选服务与入口 | 参考文档 |
|---|---|---|---|
| **收集表 / 表单 / 问卷 / 投票 / 打卡 / 接龙 / 文件收集** | **`form`** | **`form-mcp`**（`form_create_*` / `form_get_context` / `form_update_content`） | **[`form/entry.md`](./form/entry.md)** & **[`form/api_reference.md`](./form/api_reference.md)** |
| **需要免费多附件自动入表汇总** | `smartsheet` | `tencent-docs`（`manage.create_file(smartsheet)` + `smartsheet.add_view(form)`） | 智能表格表单视图 |
| 智能文档 / 报告 / 笔记 / Markdown 落盘 | `smartcanvas` | `tencent-docs`（`create_smartcanvas_by_mdx`） | 官方 smartcanvas 规范 |
| Word 文档精细排版 | `doc` | `doc-mcp` | 官方 doc-mcp 规范 |
| Excel 电子表格计算与统计 | `sheet` | `sheet-mcp` | 官方 sheet-mcp 规范 |
| PPT 幻灯片生成与改页 | `slide` | `slide-mcp` | 官方 slide-mcp 规范 |
| 思维导图 / 流程图 | `mind` / `flowchart` | `tencent-docs`（`create_mind_by_markdown` / `create_flowchart_by_mermaid`） | 官方 diagram 规范 |
| 文件重命名 / 移动 / 删除 / 权限 / 空间管理 | `manage` | `tencent-docs`（`manage.*`） | 官方 manage 规范 |

---

## 调用方式（mcporter）

```bash
# 1. 查看工具列表与 Schema（调用未知参数前必须先查）
mcporter list form-mcp
mcporter list form-mcp --schema

# 2. 调用 form-mcp 工具
mcporter call "form-mcp" "form_create_normal" --args '{"title":"示例收集表","questions":[...]}'
mcporter call "form-mcp" "form_get_context" --args '{"file_id":"300000000$xxx"}'
mcporter call "form-mcp" "form_update_content" --args '{"file_id":"300000000$xxx","base_version":{"base_pos":58,"base_revision":2},"operations":[...]}'
```

---

## 核心规则（尤其是收集表 `form-mcp`）

1. **严禁用 `manage.create_file(file_type="form")` 替代 `form-mcp`**：`manage.create_file` 只能建空白收集表，编辑题目、查询结果、配置周期一律走 `form-mcp`。
2. **编辑收集表必须先回读 `form_get_context`**：所有 `form_update_content` 写操作必须原样回传最新的 `base_version`（`base_pos` 与 `base_revision`），否则触发 `510001` 版本冲突。
3. **`update_question` 参数层级**：`question_id` 必须放在 `update_question` 顶层（与 `question`、`update_fields` 同级），且 `update_fields` 必须显式列出要更新的字段路径。
4. **正确处理 `510002` 会员权益错误**：`QUESTION_TYPE_SEGMENTATION`（分节）和 `QUESTION_TYPE_TABLE`（表格题）需要腾讯文档会员。非会员账号收到 `510002` 时，自动降级为 L1 免费方案（选项内嵌说明 + 非必填附属题 + 图片/文件上传题，或改用智能表格表单视图）。
5. **不臆造条件逻辑接口**：截至目前，腾讯文档全链路公开接口均未开放题目显隐/跳转 `logic` 字段。遇到条件显隐需求时，按 `form/entry.md` 中的 **L1 结构收敛方案** 落地，并告知用户在编辑页 UI 补充逻辑设置；协议层演进规范详见 [`references/form_logic_rfc.md`](./references/form_logic_rfc.md)。
6. **错误码速查**：
   - `400006`：Token 鉴权失败，检查 `~/.mcporter/mcporter.json` 中的 `Authorization`
   - `400016`：文档类型不匹配，确认是否用错了服务（如用 `tencent-docs` 改 `form`）
   - `11607`：请求参数不合法，对照 `mcporter list <service> --schema` 核对枚举和层级
   - `510001`：收集表版本过期，重新调用 `form_get_context` 获取最新 `base_version`
   - `510002`：功能需要腾讯文档会员（如分节符、表格题），切换免费替代方案

## 相关参考文档

- [`form/entry.md`](./form/entry.md) — 原生收集表（`form-mcp`）完整工作流与避坑指南
- [`form/api_reference.md`](./form/api_reference.md) — `form-mcp` 全部 22 个工具 API 参考
- [`references/form_logic_rfc.md`](./references/form_logic_rfc.md) — 收集表逻辑显隐/跳转接口 L2 提案规范（RFC）
- [`references/auth_and_endpoints.md`](./references/auth_and_endpoints.md) — 5 端点鉴权与配置说明
