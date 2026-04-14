# GitHub Copilot Pro+ System SOP

> Owner: icanforyouthebest-bot | Last updated: 2026-04-14
> Red team verifiable deployment blueprint

## Account Status

| Item | Value |
|------|-------|
| Plan | Copilot Pro+ ($39/mo) + GitHub Pro ($48/yr) |
| Premium Requests | 1,500/mo (Pro+ tier) |
| Budget | All $0 + Stop usage (locked) |

## Step 1: Core Repos (Forked)

```bash
git clone https://github.com/icanforyouthebest-bot/github-mcp-server.git
git clone https://github.com/icanforyouthebest-bot/copilot-sdk.git
git clone https://github.com/icanforyouthebest-bot/awesome-copilot.git
git clone https://github.com/icanforyouthebest-bot/github-copilot-configs.git
```

## Step 2: MCP Server Setup

### Option A: Remote (recommended)
VS Code 1.101+ -> Ctrl+Shift+P -> `GitHub MCP: Install Remote Server` -> OAuth

### Option B: Manual config
Create `.vscode/mcp.json`:
```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

### Option C: Docker local
```bash
docker pull ghcr.io/github/github-mcp-server
```

## Step 3: SDK Install

```bash
npm install @github/copilot-sdk
pip install github-copilot-sdk
```

## Step 4: Lockdown Config

```bash
# Read-only mode
GITHUB_READ_ONLY=1

# Lockdown mode
GITHUB_LOCKDOWN_MODE=1

# Toolset whitelist
GITHUB_TOOLSETS="repos,issues,pull_requests"

# Individual tool whitelist
GITHUB_TOOLS="get_file_contents,issue_read"
```

## Step 5: Verification

```bash
# MCP ping
curl -I https://api.githubcopilot.com/mcp/_ping
# Expected: 200 OK

# SDK check
npm list @github/copilot-sdk

# Docker tool search
docker run -it --rm ghcr.io/github/github-mcp-server tool-search "issue" --max-results 5
```

## Red Team Verification Table

| # | Check | URL | Expected |
|---|-------|-----|----------|
| 1 | Pro+ active | github.com/settings/copilot/features | Pro+ is active |
| 2 | Claude agent ON | github.com/settings/copilot/coding_agent | aria-pressed=true |
| 3 | Codex agent ON | same as above | aria-pressed=true |
| 4 | Fork: mcp-server | github.com/icanforyouthebest-bot/github-mcp-server | exists |
| 5 | Fork: sdk | github.com/icanforyouthebest-bot/copilot-sdk | exists |
| 6 | Fork: awesome | github.com/icanforyouthebest-bot/awesome-copilot | exists |
| 7 | Fork: configs | github.com/icanforyouthebest-bot/github-copilot-configs | exists |
| 8 | Dependabot ON | github.com/settings/security_analysis | all enabled |
| 9 | Budget locked | github.com/settings/billing/budgets | 5x $0 |
| 10 | 9 Apps installed | github.com/settings/installations | 9 apps |

## Installed Apps

1. Claude
2. ChatGPT Codex Connector
3. Cursor
4. Cloudflare Workers and Pages
5. Devin.ai Integration
6. Linear
7. lovable.dev
8. Railway App
9. Vercel

## Source Matrix

| Component | Source | Type |
|-----------|--------|------|
| MCP Server | github/github-mcp-server | Official |
| SDK | github/copilot-sdk | Official |
| Skills/Agents | github/awesome-copilot | Official |
| VS Code Config | doggy8088/github-copilot-configs | Community (TW) |
| Extensions | github.com/marketplace | Official |
| MCP Registry | github.com/mcp | Official |
| Skills Platform | skills.github.com | Official |


## 獨立紅隊驗證條款 (Independent Red Team Verification)

> 本系統必須通過獨立紅隊驗證，不信任任何自我回報結果。

### 驗證項目

| # | 檢查項目 | 驗證方式 | 通過條件 |
|---|---------|---------|----------|
| 1 | Fork Repo 存活 | curl raw.githubusercontent.com (bypass cache) | 全部 HTTP 200 |
| 2 | Actions 執行記錄 | GitHub API /actions/runs | run_id 非 null |
| 3 | SOP 合規條款 | grep "獨立紅隊" README.md | 存在 |
| 4 | Workflow YAML | curl health-check.yml | HTTP 200 |
| 5 | 驗證腳本完整 | curl verify.sh + redteam-verify.sh | HTTP 200 |

### 執行方式

```bash
# 本地執行
export GITHUB_TOKEN=ghp_xxxx
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
export AUDIT_TOKEN=your_audit_token
bash scripts/redteam-verify.sh

# GitHub Actions 自動執行
# 見 .github/workflows/redteam-verify.yml (每日 + 手動觸發)
```

### 審計軌跡

- 驗證結果寫入 `https://aiforseo.vip/api/audit`
- Slack 即時通知
- GitHub Actions 日誌不可竄改

> ⚠️ 任何驗證失敗 = 系統不合格，禁止上線
