#!/usr/bin/env bash
# 一键将腾讯文档官方 form-mcp (https://docs.qq.com/api/v6/form/mcp) 注册到 ~/.mcporter/mcporter.json
set -euo pipefail

CFG_PATH="${HOME}/.mcporter/mcporter.json"
if [[ ! -f "${CFG_PATH}" ]]; then
  echo "错误：未找到 ${CFG_PATH}，请先完成腾讯文档基础 MCP 授权配置。" >&2
  exit 1
fi

python3 - "${CFG_PATH}" <<'PY'
import json, sys
cfg_path = sys.argv[1]
with open(cfg_path, "r", encoding="utf-8") as f:
    cfg = json.load(f)

servers = cfg.get("mcpServers") or {}
src = None
for name in ("doc-mcp", "tencent-docs", "sheet-mcp", "slide-mcp"):
    if name in servers and servers[name].get("headers"):
        src = servers[name]
        break

if not src:
    sys.exit("错误：未在 mcporter.json 中找到包含 headers 的腾讯文档服务配置。")

existed = "form-mcp" in servers
servers["form-mcp"] = {
    "baseUrl": "https://docs.qq.com/api/v6/form/mcp",
    "headers": src["headers"],
}
cfg["mcpServers"] = servers

with open(cfg_path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("已更新 form-mcp 配置。" if existed else f"已成功添加 form-mcp 到 {cfg_path}。")
PY

echo "正在验证 form-mcp 连通性..."
mcporter list form-mcp | tail -n 5
