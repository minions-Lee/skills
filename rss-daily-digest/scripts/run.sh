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

cd "$SKILL_DIR"

run_step() {
  local step="$1"
  local script="$2"
  echo ""
  echo "═══════════════════════════════════════"
  echo "  [$step] $(date '+%H:%M:%S')"
  echo "═══════════════════════════════════════"
  npx tsx "scripts/$script"
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
    run_step "Format Report" "format-report.ts"
    ;;
  notify)
    run_step "DingTalk Notify" "notify-dingtalk.ts"
    ;;
  summarize)
    run_step "AI Summarize" "summarize-standalone.ts"
    ;;
  pipeline)
    echo "Starting full pipeline..."
    START_TIME=$(date +%s)

    run_step "1/6 Parse Feeds" "parse-feeds.ts"
    run_step "2/6 Fetch Feeds" "fetch-feeds.ts"
    run_step "3/6 Dedupe & Filter" "dedupe-filter.ts"
    run_step "4/6 AI Summarize" "summarize-standalone.ts"
    run_step "5/6 Format Report" "format-report.ts"
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
    echo "  summarize  AI summarization (Claude API)"
    echo "  pipeline   Full pipeline (all steps)"
    echo ""
    echo "Interactive mode: use /rss-digest in Claude Code"
    ;;
esac
