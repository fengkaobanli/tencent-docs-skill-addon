# `form-mcp` 全部 22 个工具 API 参考

端点：`https://docs.qq.com/api/v6/form/mcp`（服务名：`mcp-FormMcpServiceService`）

> 提示：调用任意工具前，可通过 `mcporter list form-mcp --schema` 获取服务端最新实时 JSON Schema。

---

## 一、创建类（7 个）

| 工具名 | 必填参数 | 说明 |
|---|---|---|
| `form_create_normal` | `title` | 创建普通收集表，支持传入 `subtitle`、`parent_id`、`questions`（每题 `question_id` 须留空） |
| `form_create_questionnaire` | `title` | 创建问卷收集表 |
| `form_create_file_collection` | `title` | 创建文件收集表，请求必须至少包含一道文件题 |
| `form_create_vote` | `title` | 创建投票收集表，请求必须至少包含一道投票题 |
| `form_create_following` | `title` | 创建接龙收集表，保留产品原生接龙主体 |
| `form_create_checkin` | `title` | 创建打卡收集表，支持 `initial_config`（不接受普通题目） |
| `form_create_by_template` | `template_id` | 按官方模板创建收集表草稿，仅状态为 `READY` 时可继续编辑 |

## 二、读取与模板类（2 个）

| 工具名 | 关键参数 | 说明 |
|---|---|---|
| `form_get_context` | `file_id` 或 `file_url` | 读取收集表标题、说明、题目、分组、能力矩阵及写入版本 `base_version`（所有写操作前置必调） |
| `form_get_template` | `template_id` | 读取官方收集表模板的题目、正文与可继承设置 |

## 三、内容与专项配置编辑类（7 个）

| 工具名 | 关键参数 | 说明 |
|---|---|---|
| `form_update_content` | `base_version` + `file_id`/`file_url` + `form_patch`/`operations` | 增量修改标题/说明及题目（支持 `add_question` / `update_question` / `change_question_kind` / `delete_question`） |
| `form_get_periodic_config` | `file_id` | 读取「定时和重复」配置（普通/问卷/文件收集/打卡支持；投票/接龙不支持） |
| `form_update_periodic_config` | `file_id`, `config` | 修改「定时和重复」配置 |
| `form_get_checkin_config` | `file_id` | 读取打卡收集表的打卡方式、选项、昵称/图片/位置与同日重复配置 |
| `form_update_checkin_config` | `file_id`, `base_version`, `patch` | 修改打卡专属配置 |
| `form_get_following_config` | `file_id` | 读取接龙收集表的预设备注 |
| `form_update_following_config` | `file_id`, `base_version`, `config` | 修改接龙收集表的预设备注 |

## 四、结果查询与统计分析类（6 个）

| 工具名 | 关键参数 | 说明 |
|---|---|---|
| `form_get_result_overview` | `file_id`/`file_url`, `scope?` | 读取提交量、回收趋势、来源分布与可分析字段概览（不返回明细） |
| `form_query_records` | `file_id`/`file_url`, `page?`, `return_questions?`, `scope?` | 按条件分页查询提交记录摘要或指定题目答案（需显式指定返回题白名单） |
| `form_get_question_stats` | `file_id`/`file_url`, `questions?`, `scope?`, `top_n?` | 按题目 ID 读取单题或少量题统计（最多 10 题，每题最多返回 50 个选项/分组） |
| `form_get_cross_analysis` | `file_id`/`file_url`, `row_fields?`, `col_fields?` | 行 × 列交叉透视分析；行列均留空时进入发现模式返回可分析字段 |
| `form_attachment_summary` | `file_id`/`file_url`, `question_ids?` | 按附件题统计提交次数（人次口径） |
| `form_submission_checklist` | `file_id`/`file_url`, `page_size`, `scope`, `cursor?` | 分页列出已提交（`SUBMISSION_SCOPE_SUBMITTED`）或未提交（`SUBMISSION_SCOPE_UNSUBMITTED`）名单 |

---

## 五、常用调用示例

### 1. 新增题目（`add_question`）
```json
{
  "file_id": "300000000$YourPadId",
  "base_version": { "base_pos": 58, "base_revision": 2 },
  "operations": [
    {
      "add_question": {
        "question": {
          "type": "QUESTION_TYPE_FILE_IMAGE",
          "title": "奖状照片上传（最多可传 6 张）",
          "subtitle": "参加过竞赛者请上传奖状照片",
          "required": false
        }
      }
    }
  ]
}
```

### 2. 局部更新题目文案与选项（`update_question`）
```json
{
  "file_id": "300000000$YourPadId",
  "base_version": { "base_pos": 226, "base_revision": 4 },
  "operations": [
    {
      "update_question": {
        "question_id": "RADIO1795580488734mwvm9g67",
        "question": {
          "subtitle": "选「否」可直接提交；选「是」请继续填写下方竞赛题",
          "config": {
            "choice": {
              "options": [
                { "option_id": "1", "label": "是（请继续填写下方竞赛名并上传奖状）" },
                { "option_id": "2", "label": "否（无需填写下方题目，直接提交）" }
              ]
            }
          }
        },
        "update_fields": ["subtitle", "config.choice.options"]
      }
    }
  ]
}
```
