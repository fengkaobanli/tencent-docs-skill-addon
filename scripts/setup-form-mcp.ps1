<#
.SYNOPSIS
  一键将腾讯文档官方 form-mcp (https://docs.qq.com/api/v6/form/mcp) 注册到 ~/.mcporter/mcporter.json，
  自动复用已有的 tencent-docs / doc-mcp 鉴权头，不打印也不泄露 Token。
#>
$ErrorActionPreference = "Stop"

$cfgPath = Join-Path $env:USERPROFILE ".mcporter\mcporter.json"
if (-not (Test-Path $cfgPath)) {
  Write-Error "未找到 $cfgPath，请先完成腾讯文档基础 MCP 授权配置。"
  exit 1
}

$cfg = Get-Content -Raw -Path $cfgPath | ConvertFrom-Json
if (-not $cfg.mcpServers) {
  Write-Error "mcporter.json 中缺少 mcpServers 字段。"
  exit 1
}

$sourceSrv = $null
foreach ($candidate in @("doc-mcp", "tencent-docs", "sheet-mcp", "slide-mcp")) {
  if ($cfg.mcpServers.PSObject.Properties.Name -contains $candidate) {
    $sourceSrv = $cfg.mcpServers.$candidate
    break
  }
}

if (-not $sourceSrv -or -not $sourceSrv.headers) {
  Write-Error "未在 mcporter.json 中找到包含 headers 的腾讯文档服务配置。"
  exit 1
}

$formSrv = [PSCustomObject]@{
  baseUrl = "https://docs.qq.com/api/v6/form/mcp"
  headers = $sourceSrv.headers
}

if ($cfg.mcpServers.PSObject.Properties.Name -contains "form-mcp") {
  $cfg.mcpServers.'form-mcp' = $formSrv
  Write-Host "已更新现有 form-mcp 配置。" -ForegroundColor Green
} else {
  $cfg.mcpServers | Add-Member -NotePropertyName "form-mcp" -NotePropertyValue $formSrv
  Write-Host "已成功添加 form-mcp 配置到 $cfgPath。" -ForegroundColor Green
}

$cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $cfgPath -Encoding UTF8

Write-Host "正在验证 form-mcp 连通性..." -ForegroundColor Cyan
mcporter list form-mcp | Select-Object -Last 5
