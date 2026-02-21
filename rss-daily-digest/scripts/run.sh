#!/usr/bin/env bash
# Unified entry point for RSS Daily AI Digest.
# Usage: ./scripts/run.sh <command>
#   parse    - Parse rss-feeds.md → feeds.json
#   fetch    - Fetch all RSS feeds
#   filter   - Dedupe + time-window filter
#   format   - Generate Markdown report
#   notify   - Send DingTalk notification
#   summarize - AI summarization (Claude API, requires ANTHROPIC_API_KEY)
#   pipeline - Full pipeline: parse → fetch → filter → summarize → format → notify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHIVE_DIR="$(cd "${ARCHIVE_DIR:-$HOME/Documents/pe/jixiaxuegong/ai-digest-archive}" 2>/dev/null && pwd)"

cd "$SKILL_DIR"

# Allow claude CLI to run even if invoked from within a Claude Code session
unset CLAUDECODE 2>/dev/null || true

# Parse --force flag
FORCE_FLAG=""
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE_FLAG="--force"
done

run_step() {
  local step="$1"
  local script="$2"
  local extra_args="${3:-}"
  echo ""
  echo "═══════════════════════════════════════"
  echo "  [$step] $(date '+%H:%M:%S')"
  echo "═══════════════════════════════════════"
  # shellcheck disable=SC2086
  npx tsx "scripts/$script" $extra_args
}

case "${1:-help}" in
  parse)
    run_step "Parse Feeds" "parse-feeds.ts"
    ;;
  fetch)
    run_step "Fetch Feeds" "fetch-feeds.ts"
    ;;
  filter)
    run_step "Dedupe & Filter" "dedupe-filter.ts"
    ;;
  format)
    run_step "Format Report" "format-report.ts" "$FORCE_FLAG"
    ;;
  notify)
    run_step "DingTalk Notify" "notify-dingtalk.ts"
    ;;
  summarize)
    run_step "AI Summarize (API)" "summarize-standalone.ts"
    ;;
  summarize-claude)
    echo ""
    echo "═══════════════════════════════════════"
    echo "  [AI Summarize via Claude CLI] $(date '+%H:%M:%S')"
    echo "═══════════════════════════════════════"
    (cd "$ARCHIVE_DIR" && claude -p "$(cat "$SKILL_DIR/scripts/summarize-prompt.md")" \
      --allowedTools "Read,Write,Task,Bash,Glob,Grep")
    ;;
  pipeline)
    echo "Starting full pipeline..."
    START_TIME=$(date +%s)

    run_step "1/6 Parse Feeds" "parse-feeds.ts"
    run_step "2/6 Fetch Feeds" "fetch-feeds.ts"

    if [ -n "$FORCE_FLAG" ]; then
      echo ""
      echo "  [--force] Clearing today's seen-guids for full re-run..."
      node --input-type=commonjs <<'EOF'
const fs = require('fs');
const path = require('path');
const guidPath = path.join(process.cwd(), 'data/seen-guids.json');
const today = new Date().toISOString().slice(0, 10);
const guids = JSON.parse(fs.readFileSync(guidPath, 'utf-8'));
let count = 0;
for (const [k, v] of Object.entries(guids)) {
  if (v.startsWith(today)) { delete guids[k]; count++; }
}
fs.writeFileSync(guidPath, JSON.stringify(guids, null, 2));
console.log('  Cleared ' + count + " today's seen-guids");
EOF
    fi

    run_step "3/6 Dedupe & Filter" "dedupe-filter.ts"

    echo ""
    echo "═══════════════════════════════════════"
    echo "  [4/6 AI Summarize via Claude CLI] $(date '+%H:%M:%S')"
    echo "═══════════════════════════════════════"
    (cd "$ARCHIVE_DIR" && claude -p "$(cat "$SKILL_DIR/scripts/summarize-prompt.md")" \
      --allowedTools "Read,Write,Task,Bash,Glob,Grep")

    run_step "5/6 Format Report" "format-report.ts" "$FORCE_FLAG"
    run_step "6/6 DingTalk Notify" "notify-dingtalk.ts"

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    echo "═══════════════════════════════════════"
    echo "  Pipeline complete in ${ELAPSED}s"
    echo "═══════════════════════════════════════"
    ;;
  help|*)
    echo "RSS Daily AI Digest"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  parse      Parse rss-feeds.md → feeds.json"
    echo "  fetch      Fetch all RSS feeds"
    echo "  filter     Dedupe + time-window filter"
    echo "  format     Generate Markdown report"
    echo "  notify     Send DingTalk notification"
    echo "  summarize        AI summarization (Claude API, requires ANTHROPIC_API_KEY)"
    echo "  summarize-claude AI summarization (Claude CLI, requires claude installed)"
    echo "  pipeline         Full pipeline (all steps, uses Claude CLI)"
    echo ""
    echo "Interactive mode: use /rss-digest in Claude Code"
    ;;
esac
