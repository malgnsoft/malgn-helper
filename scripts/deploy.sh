#!/usr/bin/env bash
# 일괄 배포 스크립트: git commit → push → Cloudflare deploy → 이력 기록
# Usage: ./scripts/deploy.sh <repo-name> "<commit message>"
# Example: ./scripts/deploy.sh malgn-helper-api "feat: 챗 엔드포인트 추가"

set -euo pipefail

REPO="${1:-}"
shift || true
MSG="${*:-}"

if [[ -z "$REPO" || -z "$MSG" ]]; then
  cat <<EOF
Usage: $0 <repo-name> "<commit message>"

Valid repo-name:
  - malgn-helper
  - malgn-helper-admin
  - malgn-helper-api
  - malgn-helper-pms

The script will run, in order:
  1. git add -A && git commit (skip if no changes)
  2. git push
  3. pnpm deploy (Workers/Pages auto-detected)
  4. append entry to doc/history/history.YYYYMMDD.md
EOF
  exit 1
fi

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS_ROOT="$(dirname "$WORKSPACE_ROOT")"
REPO_DIR="$PROJECTS_ROOT/$REPO"
DATE_KR="$(date +%Y-%m-%d)"
DATE_FILE="$(date +%Y%m%d)"
TIME_HM="$(date +%H:%M)"
HISTORY_DIR="$WORKSPACE_ROOT/doc/history"
HISTORY_FILE="$HISTORY_DIR/history.${DATE_FILE}.md"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "ERROR: $REPO_DIR is not a git repository"
  exit 1
fi

echo "▶ [$REPO] 배포 시작 ($DATE_KR $TIME_HM)"
cd "$REPO_DIR"

# 1) commit
echo "  [1/4] git commit"
git add -A
if git diff --cached --quiet; then
  echo "    ⚠ 변경 없음 — 커밋 skip"
  COMMITTED="no"
else
  git commit -m "$MSG"
  COMMITTED="yes"
fi
COMMIT_SHA="$(git rev-parse --short HEAD)"
echo "    ✓ HEAD = $COMMIT_SHA"

# 2) push
echo "  [2/4] git push"
git push
echo "    ✓ origin/$(git rev-parse --abbrev-ref HEAD)"

# 3) deploy
echo "  [3/4] cloudflare deploy"
DEPLOY_KIND="Cloudflare Workers"
[[ -f "$REPO_DIR/wrangler.toml" ]] && DEPLOY_KIND="Cloudflare Pages"
pnpm deploy 2>&1 | tail -20
echo "    ✓ $DEPLOY_KIND"

# 4) history append
echo "  [4/4] history 기록"
mkdir -p "$HISTORY_DIR"
if [[ ! -f "$HISTORY_FILE" ]]; then
  printf "# 작업 이력 — %s\n\n" "$DATE_KR" > "$HISTORY_FILE"
fi
if ! grep -q '^## 배포$' "$HISTORY_FILE"; then
  printf "\n## 배포\n" >> "$HISTORY_FILE"
fi
{
  printf "\n### %s — \`%s\` → %s\n" "$TIME_HM" "$REPO" "$DEPLOY_KIND"
  printf -- "- 커밋: \`%s\` (신규 커밋: %s)\n" "$COMMIT_SHA" "$COMMITTED"
  printf -- "- 메시지: %s\n" "$MSG"
} >> "$HISTORY_FILE"
echo "    ✓ $HISTORY_FILE"

echo
echo "✅ 배포 완료: $REPO ($COMMIT_SHA)"
echo "   이력: $HISTORY_FILE"
