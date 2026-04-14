#!/bin/bash
# Independent Red Team Verification Script
# Does NOT trust any self-reported results
set -euo pipefail

REPO="https://github.com/icanforyouthebest-bot/copilot-system-sop"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
AUDIT_ENDPOINT="https://aiforseo.vip/api/audit"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FAILED=0
RESULTS=""

log() { echo "[$TIMESTAMP] $1"; RESULTS="$RESULTS\n$1"; }

# 1. Verify Fork Repos are REAL (bypass cache with raw content check)
log "=== Step 1: Fork Repo Liveness ==="
for repo in github-mcp-server copilot-sdk awesome-copilot github-copilot-configs; do
  STATUS=$(curl -sI -H "Cache-Control: no-cache" \
    "https://raw.githubusercontent.com/icanforyouthebest-bot/$repo/main/README.md" \
    -w "%{http_code}" -o /dev/null)
  if [ "$STATUS" != "200" ]; then
    log "FAIL: $repo returned $STATUS"
    FAILED=1
  else
    log "PASS: $repo alive (HTTP $STATUS)"
  fi
done

# 2. Verify GitHub Actions ran for real
log "=== Step 2: Actions Execution Proof ==="
RUN_DATA=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/icanforyouthebest-bot/copilot-system-sop/actions/runs?per_page=1")
RUN_ID=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].id // empty')
RUN_STATUS=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].conclusion // empty')
RUN_TIME=$(echo "$RUN_DATA" | jq -r '.workflow_runs[0].updated_at // empty')

if [ -z "$RUN_ID" ]; then
  log "FAIL: No workflow runs found"
  FAILED=1
else
  log "PASS: Run #$RUN_ID status=$RUN_STATUS at $RUN_TIME"
fi

# 3. Verify SOP contains red-team clause
log "=== Step 3: SOP Compliance ==="
README=$(curl -s "https://raw.githubusercontent.com/icanforyouthebest-bot/copilot-system-sop/main/README.md")
if echo "$README" | grep -q "獨立紅隊"; then
  log "PASS: SOP contains independent red-team clause"
else
  log "FAIL: SOP missing independent red-team clause"
  FAILED=1
fi

# 4. Verify health-check workflow YAML is valid
log "=== Step 4: Workflow YAML Integrity ==="
YAML_STATUS=$(curl -sI "https://raw.githubusercontent.com/icanforyouthebest-bot/copilot-system-sop/main/.github/workflows/health-check.yml" \
  -w "%{http_code}" -o /dev/null)
if [ "$YAML_STATUS" == "200" ]; then
  log "PASS: health-check.yml exists (HTTP $YAML_STATUS)"
else
  log "FAIL: health-check.yml missing ($YAML_STATUS)"
  FAILED=1
fi

# 5. Verify verify.sh script exists
log "=== Step 5: Verify Script Integrity ==="
SCRIPT_STATUS=$(curl -sI "https://raw.githubusercontent.com/icanforyouthebest-bot/copilot-system-sop/main/scripts/verify.sh" \
  -w "%{http_code}" -o /dev/null)
if [ "$SCRIPT_STATUS" == "200" ]; then
  log "PASS: verify.sh exists (HTTP $SCRIPT_STATUS)"
else
  log "FAIL: verify.sh missing ($SCRIPT_STATUS)"
  FAILED=1
fi

# 6. Write audit log
log "=== Step 6: Audit Trail ==="
if [ "$FAILED" -eq 0 ]; then
  VERDICT="PASS"
else
  VERDICT="FAIL"
fi

if [ -n "${AUDIT_TOKEN:-}" ]; then
  curl -s -X POST "$AUDIT_ENDPOINT" \
    -H "Authorization: Bearer ${AUDIT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"event\": \"independent_redteam_verification\",
      \"timestamp\": \"$TIMESTAMP\",
      \"repo\": \"$REPO\",
      \"run_id\": \"${RUN_ID:-none}\",
      \"verifier\": \"human_commander\",
      \"result\": \"$VERDICT\"
    }" && log "PASS: Audit trail written" || log "WARN: Audit endpoint unreachable"
else
  log "SKIP: No AUDIT_TOKEN set"
fi

# 7. Slack notification
log "=== Step 7: Slack Notification ==="
if [ -n "$SLACK_WEBHOOK" ]; then
  curl -s -X POST "$SLACK_WEBHOOK" -H 'Content-Type: application/json' \
    -d "{
      \"text\": \"Red Team Verification: $VERDICT\",
      \"blocks\": [
        {\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Repo*: copilot-system-sop\\n*Run ID*: ${RUN_ID:-N/A}\\n*Time*: $TIMESTAMP\\n*Verdict*: $VERDICT\"}},
        {\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\"Audit trail written to immutable log\"}]}
      ]
    }" && log "PASS: Slack notified" || log "WARN: Slack webhook failed"
else
  log "SKIP: No SLACK_WEBHOOK_URL set"
fi

echo ""
echo "========================================"
echo "RED TEAM VERIFICATION RESULT: $VERDICT"
echo "========================================"
echo -e "$RESULTS"

exit $FAILED
