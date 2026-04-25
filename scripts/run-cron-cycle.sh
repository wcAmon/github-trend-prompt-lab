#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPO_WORKDIR="$ROOT/repos/${STAMP}"
mkdir -p snapshots prompt-packs single-html logs "$REPO_WORKDIR"

cleanup_repos() {
  if [[ "${ZODIAC_KEEP_REPOS:-0}" == "1" ]]; then
    return
  fi
  if [[ -n "${REPO_WORKDIR:-}" && "$REPO_WORKDIR" == "$ROOT/repos/"* ]]; then
    rm -rf "$REPO_WORKDIR"
  fi
}
trap cleanup_repos EXIT

if [[ "${ZODIAC_SKIP_ENV_FILE:-0}" != "1" && -f "$HOME/.config/github-trend-prompt-lab.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/github-trend-prompt-lab.env"
fi

SNAPSHOT="snapshots/${STAMP}.json"
node scripts/discover-trends.mjs > "$SNAPSHOT"

MAX_ANALYZE_REPOS="${MAX_ANALYZE_REPOS:-3}"
PROMPT="$(
  sed \
    -e "s|{{SNAPSHOT}}|${SNAPSHOT}|g" \
    -e "s|{{REPO_WORKDIR}}|${REPO_WORKDIR}|g" \
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

env \
  -u ZODIAC_TEACH_SERVER_API_KEY \
  -u GITHUB_TOKEN \
  -u GH_TOKEN \
  -u GIT_ASKPASS \
  "$CODEX_BIN" "${CODEX_ARGS[@]}" "$PROMPT" > "logs/zodiac-${STAMP}.log" 2>&1

if [[ "${ZODIAC_SKIP_PUBLISH:-0}" != "1" && -n "${ZODIAC_TEACH_SERVER_API_KEY:-}" ]]; then
  node scripts/publish-pages.mjs
fi
