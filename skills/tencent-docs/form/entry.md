# 原生收集表（`form-mcp`）完整工作流指南

腾讯文档独立收集表由官方 `form-mcp` 服务（`https://docs.qq.com/api/v6/form/mcp`）驱动，提供 22 个专用工具，覆盖**创建 → 回读 → 增量编辑 → 周期配置 → 结果分析**全生命周期。

---

## 一、创建类工具选择

根据收集表形态选择对应的创建入口（创建时 `question_id` 必须留空）：

| 场景 | 工具 | 特点 |
|---|---|---|
| 普通信息登记 / 报名 / 材料收集 | `form_create_normal` | 最通用，支持文本、单选、多选、下拉、图片、文件等题型 |
| 调查问卷 | `form_create_questionnaire` | 问卷模板，适合量表、评分、矩阵等 |
| 文件 / 作业 / 证明材料收集 | `form_create_file_collection` | 必须至少包含一道文件题（`QUESTION_TYPE_FILE`） |
| 投票评选 | `form_create_vote` | 必须至少包含一道投票题（`QUESTION_TYPE_VOTE`） |
| 群接龙 | `form_create_following` | 保留原生接龙主体，可用 `form_update_following_config` 改预设备注 |
| 每日打卡 | `form_create_checkin` | 打卡主体由模板提供，用 `form_update_checkin_config` 配打卡项 |
| 复用官方模板 | `form_get_template` → `form_create_by_template` | 仅返回 `READY` 时可继续编辑 |

---

## 二、标准编辑工作流（读-改-验）

### 1. 先回读上下文（必做）
```bash
mcporter call "form-mcp" "form_get_context" --args '{"file_id":"300000000$xxxx"}'
```
记录返回的：
- `base_version`: `{"base_pos": ..., "base_revision": ...}`
- 各题目的 `question_id` 与选项的 `option_id`
- `capabilities`（明确每道题允许修改的 `allowed_update_fields`）

### 2. 构造 `form_update_content` 操作
`operations` 数组每项支持 4 种操作之一：
- `add_question`：新增题目（可通过 `insert_after_question_id` 指定插入位置）
- `update_question`：不改题型，局部更新字段
  - ⚠️ **关键约束**：`question_id` 必须放在 `update_question` 顶层，且必须传 `update_fields`（如 `["subtitle", "config.choice.options"]`）；更新既有选项时保留 `option_id`。
- `change_question_kind`：切换题型
- `delete_question`：删除题目

### 3. 回读确认
写入成功后会返回新的 `version`（`base_pos` / `base_revision`）。如果多人同时编辑导致返回 `510001`，重新调用 `form_get_context` 获取最新版本号再提交即可。

---

## 三、实测题型权限与避坑表

以下基于真实 `form-mcp` 调用验证：

| 题型枚举 | 中文名 | 非会员账号 | 关键配置与注意点 |
|---|---|---|---|
| `QUESTION_TYPE_SIMPLE` | 填空/文本 | ✅ 可用 | `config.text.data_type` 默认 `DATA_TYPE_TEXT`，支持手机号/邮箱/数字/货币校验 |
| `QUESTION_TYPE_RADIO` | 单选 | ✅ 可用 | `config.choice.options` 为 `[{"label":"..."}]` |
| `QUESTION_TYPE_CHECKBOX` | 多选 | ✅ 可用 | 支持 `selection_limit` |
| `QUESTION_TYPE_SELECT` | 下拉选择 | ✅ 可用 | 同 `config.choice` |
| `QUESTION_TYPE_FILE_IMAGE` | 图片上传 | ✅ 可用 | 单题默认最多上传 **6 张**图片 |
| `QUESTION_TYPE_FILE` | 文件上传 | ✅ 可用 | 单题默认最多上传 **1 个**文件；如省略 `config.attachment` 则走前端默认，避免不合法的 `file_types` 触发 `11607` |
| `QUESTION_TYPE_SEGMENTATION` | 分节符 | ⚠️ 需会员 | 非会员调用返回 `510002` |
| `QUESTION_TYPE_TABLE` | 表格题（动态多行） | ⚠️ 需会员 | 列支持 `SIMPLE` / `SELECT` / `FILE` / `FILE_IMAGE` 等；会员账号可实现单次提交多行录入，非会员返回 `510002` |

---

## 四、无条件逻辑接口时的 L1 实用方案

截至目前，腾讯文档全链路 API（`form-mcp` / 开放平台 / 企业微信）均未开放题目**显示逻辑 / 跳转逻辑**字段。实际落地时按账号权益采用以下 L1 收敛方案：

1. **有会员账号（体验最佳）**：
   - 使用 `QUESTION_TYPE_SEGMENTATION` 划分区块；
   - 使用 `QUESTION_TYPE_TABLE`（表格题）把「竞赛名称 + 获奖等级 + 奖状上传」放进同一张表，填报人一次提交内点「+ 添加一行」即可录入多项，且未参加者留空直接提交。
2. **非会员账号（零门槛稳定落地）**：
   - **选项内嵌引导**：在触发单选题的选项文案里直接说明路径，例如：
     - `是（请继续填写下方竞赛名称并上传奖状材料，多项竞赛可多次提交）`
     - `否（无需填写下方竞赛题，直接点击提交即可）`
   - **附属题全设 `required: false`**：避免选「否」的填报人被拦截无法提交。
   - **多文件上传组合**：同时提供 `QUESTION_TYPE_FILE_IMAGE`（一次最多 6 张奖状图）与 `QUESTION_TYPE_FILE`（PDF/压缩包）。
   - **可选替代方案（智能表格表单视图）**：若需要**免费单题多附件上传 + 自动入表汇总统计**，改用 `tencent-docs` 的 `manage.create_file(file_type="smartsheet")` + `smartsheet.add_fields`（`attachment` 字段）+ `smartsheet.add_view(view_type="form")`。
3. **如需强条件显隐**：
   - 先用 `form-mcp` 把 95% 的题目结构生成好，再让创建者在网页编辑页点 2 下开启逻辑显示规则。
