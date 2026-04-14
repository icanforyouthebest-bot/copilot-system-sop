#!/bin/bash
set -e
echo '=== Copilot Pro+ System Verification ==='
echo ''

# 1. MCP API
echo -n '[1] MCP API ping: '
S=$(curl -s -o /dev/null -w '%{http_code}' https://api.githubcopilot.com/mcp/_ping)
[ "$S" = "200" ] && echo "PASS ($S)" || echo "FAIL ($S)"

# 2. Docker MCP image
echo -n '[2] MCP Docker: '
docker pull ghcr.io/github/github-mcp-server:latest > /dev/null 2>&1 && echo 'PASS' || echo 'FAIL'

# 3. SDK npm
echo -n '[3] SDK npm: '
npm view @github/copilot-sdk version > /dev/null 2>&1 && echo 'PASS' || echo 'NOT FOUND'

# 4. Forked repos
for R in github-mcp-server copilot-sdk awesome-copilot github-copilot-configs; do
  echo -n "[4] Fork $R: "
  S=$(curl -s -o /dev/null -w '%{http_code}' https://api.github.com/repos/icanforyouthebest-bot/$R)
  [ "$S" = "200" ] && echo 'PASS' || echo "FAIL ($S)"
done

# 5. GitHub user plan
echo -n '[5] User plan: '
curl -s https://api.github.com/users/icanforyouthebest-bot | jq -r '.plan.name // "unknown"'

echo ''
echo '=== Verification Complete ==='
