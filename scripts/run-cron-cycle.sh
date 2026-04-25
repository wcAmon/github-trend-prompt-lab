#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p snapshots prompt-packs single-html logs repos

if [[ -f "$HOME/.config/github-trend-prompt-lab.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/github-trend-prompt-lab.env"
fi

SNAPSHOT="snapshots/${STAMP}.json"
node scripts/discover-trends.mjs > "$SNAPSHOT"

MAX_ANALYZE_REPOS="${MAX_ANALYZE_REPOS:-3}"
PROMPT="$(
  sed \
    -e "s|{{SNAPSHOT}}|${SNAPSHOT}|g" \
    -e "s|{{MAX_ANALYZE_REPOS}}|${MAX_ANALYZE_REPOS}|g" \
    prompts/static-rebuild-pack.md
)"

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
CODEX_ARGS=(exec --cd "$ROOT")
if [[ "${ZODIAC_BYPASS_CODEX_SANDBOX:-0}" == "1" ]]; then
  CODEX_ARGS+=(--dangerously-bypass-approvals-and-sandbox)
else
  CODEX_ARGS+=(--sandbox workspace-write --full-auto)
fi
if [[ -n "$CODEX_MODEL" ]]; then
  CODEX_ARGS+=(--model "$CODEX_MODEL")
fi

"$CODEX_BIN" "${CODEX_ARGS[@]}" "$PROMPT" > "logs/zodiac-${STAMP}.log" 2>&1

if [[ -n "${ZODIAC_TEACH_SERVER_API_KEY:-}" ]]; then
  node scripts/publish-pages.mjs
fi
