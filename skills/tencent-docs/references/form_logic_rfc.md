# RFC：收集表条件显隐与跳转逻辑接口规范（L2 提案）

## 一、现状调研结论

经对腾讯文档全链路接口核查（官方 `form-mcp` 22 个工具、通用 `tencent-docs` 240 个工具、企业微信 `wedoc/create_collect` 开放接口及社区逆向项目），**逻辑显示 / 逻辑跳转功能目前仅存在于网页编辑器 UI，未在任何公开 API 中暴露 `logic` 字段**。

本 RFC 定义标准化的 L2 MCP 协议层接口规范，用于未来官方开放接口或插件升级时的无缝对接。

---

## 二、建议新增工具：`form_update_logic`

### 1. 工具签名

```jsonc
{
  "name": "form_update_logic",
  "description": "配置收集表的显示逻辑与逻辑跳转。写入前必须回读 form_get_context 获取 base_version。",
  "required": ["base_version", "operations"],
  "properties": {
    "file_id":  { "type": "string" },
    "file_url": { "type": "string" },
    "base_version": {
      "properties": {
        "base_pos":      { "type": "integer" },
        "base_revision": { "type": "integer" }
      }
    },
    "operations": {
      "type": "array",
      "items": {
        "properties": {
          "op":      { "enum": ["ADD", "UPDATE", "DELETE", "CLEAR"] },
          "rule_id": { "type": "string" },
          "rule":    { "$ref": "#/definitions/logic_rule" }
        }
      }
    }
  }
}
```

### 2. 核心结构：`logic_rule`

```jsonc
{
  "rule_id": "logic-1",              // ADD 时留空，由服务端生成；UPDATE/DELETE 时必填
  "enabled": true,
  "mode": "SHOW",                    // SHOW | HIDE | JUMP（同一触发题下互斥）
  "trigger": {
    "question_id": "RADIO...",       // 触发题 ID（须为选择类题型）
    "condition": "IS",               // 见下方 condition 枚举
    "option_ids": ["1"],             // 回读后保留原 option_id
    "value": ""                      // 仅 IS_EMPTY / 文本匹配类使用
  },
  "targets": [                       // SHOW/HIDE 可多题；JUMP 仅允许 1 题
    "SIMPLE...",
    "FILE..."
  ],
  "priority": 100                    // 同题多规则冲突时数值大者优先
}
```

### 3. `condition` 枚举

| `condition` | 适用题型 | 语义 |
|---|---|---|
| `IS` | 单选 / 下拉 / 单选投票 | 等于指定选项 |
| `IS_NOT` | 单选 / 下拉 | 不等于指定选项 |
| `CONTAINS` | 多选 / 排序 | 勾选了指定选项 |
| `NOT_CONTAINS` | 多选 | 未勾选指定选项 |
| `ANY_OF` | 多选 | 命中任一指定选项 |
| `NONE_OF` | 多选 | 全未命中 |
| `IS_EMPTY` / `IS_NOT_EMPTY` | 文本 / 数字 / 日期 | 是否填写 |

### 4. 必须内置的 6 条安全校验

1. **触发题型限制**：`trigger.question_id` 必须为 `RADIO / CHECKBOX / SELECT / SORT / VOTE`（文本类不可直接作为选项触发源）。
2. **禁止自引用**：`targets` 不得包含 `trigger.question_id` 本身。
3. **环路检测**：禁止 `A -> B -> A` 循环依赖。
4. **跳转顺序约束**：`mode=JUMP` 时目标题顺序必须大于触发题（禁止往回跳）。
5. **必填冲突保护**：被 `mode=SHOW` 控制的题目若 `required=true`，需在隐藏态自动豁免必填或提示降级，避免条件未命中时表单无法提交。
6. **跳转目标唯一**：`mode=JUMP` 时 `targets.length === 1`。

---

## 三、`form_get_context` 配套回读扩展

为了满足「写前预览 + 版本锁」原则，`form_get_context` 响应需同步增加 `logic_rules` 数组：

```jsonc
{
  "questions": [ /* 原样 */ ],
  "logic_rules": [
    {
      "rule_id": "logic-1",
      "mode": "SHOW",
      "trigger": { "question_id": "RADIO...", "condition": "IS", "option_ids": ["1"] },
      "targets": ["SIMPLE...", "FILE..."],
      "enabled": true
    }
  ]
}
```
