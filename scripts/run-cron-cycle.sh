#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p snapshots prompt-packs logs repos

if [[ -f "$HOME/.config/github-trend-prompt-lab.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/github-trend-prompt-lab.env"
fi

SNAPSHOT="snapshots/${STAMP}.json"
node scripts/discover-trends.mjs > "$SNAPSHOT"

PROMPT="$(sed "s|{{SNAPSHOT}}|${SNAPSHOT}|g" prompts/static-rebuild-pack.md)"

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
CODEX_ARGS=(exec --cd "$ROOT" --sandbox workspace-write --ask-for-approval never)
if [[ -n "$CODEX_MODEL" ]]; then
  CODEX_ARGS+=(--model "$CODEX_MODEL")
fi

"$CODEX_BIN" "${CODEX_ARGS[@]}" "$PROMPT" > "logs/codex-${STAMP}.log" 2>&1
