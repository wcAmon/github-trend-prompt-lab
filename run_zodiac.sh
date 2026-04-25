#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Run zodiac once by hand.

Usage:
  ./run_zodiac.sh [options]

Options:
  --repos N          Number of candidate repos zodiac should analyze. Default: 1
  --per-page N       GitHub search results per license query. Default: 2
  --min-stars N      Minimum stars for candidate discovery. Default: 1000
  --max-size-kb N    Maximum repository size in KiB. Default: 2500
  --no-publish       Generate local prompt packs and HTML, but do not upload.
  --keep-repos       Keep temporary repo checkouts for debugging.
  --bypass-sandbox   Run Codex CLI without its sandbox.
  --sandbox          Run Codex CLI with its sandbox. Default.
  -h, --help         Show this help.

Outputs:
  logs/zodiac-<timestamp>.log
  snapshots/<timestamp>.json
  prompt-packs/*.json
  single-html/*.html

Notes:
  This script reads ~/.config/github-trend-prompt-lab.env when present.
  CLI options override values from that file.
  Temporary repo checkouts are deleted by default.
USAGE
}

CALLER_MAX_ANALYZE_REPOS="${MAX_ANALYZE_REPOS-}"
CALLER_PER_PAGE="${PER_PAGE-}"
CALLER_MIN_STARS="${MIN_STARS-}"
CALLER_MAX_SIZE_KB="${MAX_SIZE_KB-}"
CALLER_ZODIAC_SKIP_PUBLISH="${ZODIAC_SKIP_PUBLISH-}"
CALLER_ZODIAC_KEEP_REPOS="${ZODIAC_KEEP_REPOS-}"
CALLER_ZODIAC_BYPASS_CODEX_SANDBOX="${ZODIAC_BYPASS_CODEX_SANDBOX-}"

if [[ -f "$HOME/.config/github-trend-prompt-lab.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/github-trend-prompt-lab.env"
fi

[[ -n "$CALLER_MAX_ANALYZE_REPOS" ]] && MAX_ANALYZE_REPOS="$CALLER_MAX_ANALYZE_REPOS"
[[ -n "$CALLER_PER_PAGE" ]] && PER_PAGE="$CALLER_PER_PAGE"
[[ -n "$CALLER_MIN_STARS" ]] && MIN_STARS="$CALLER_MIN_STARS"
[[ -n "$CALLER_MAX_SIZE_KB" ]] && MAX_SIZE_KB="$CALLER_MAX_SIZE_KB"
[[ -n "$CALLER_ZODIAC_SKIP_PUBLISH" ]] && ZODIAC_SKIP_PUBLISH="$CALLER_ZODIAC_SKIP_PUBLISH"
[[ -n "$CALLER_ZODIAC_KEEP_REPOS" ]] && ZODIAC_KEEP_REPOS="$CALLER_ZODIAC_KEEP_REPOS"
[[ -n "$CALLER_ZODIAC_BYPASS_CODEX_SANDBOX" ]] && ZODIAC_BYPASS_CODEX_SANDBOX="$CALLER_ZODIAC_BYPASS_CODEX_SANDBOX"

MAX_ANALYZE_REPOS="${MAX_ANALYZE_REPOS:-1}"
PER_PAGE="${PER_PAGE:-2}"
MIN_STARS="${MIN_STARS:-1000}"
MAX_SIZE_KB="${MAX_SIZE_KB:-2500}"
ZODIAC_BYPASS_CODEX_SANDBOX="${ZODIAC_BYPASS_CODEX_SANDBOX:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repos)
      MAX_ANALYZE_REPOS="$2"
      shift 2
      ;;
    --per-page)
      PER_PAGE="$2"
      shift 2
      ;;
    --min-stars)
      MIN_STARS="$2"
      shift 2
      ;;
    --max-size-kb)
      MAX_SIZE_KB="$2"
      shift 2
      ;;
    --no-publish)
      ZODIAC_SKIP_PUBLISH=1
      shift
      ;;
    --keep-repos)
      ZODIAC_KEEP_REPOS=1
      shift
      ;;
    --bypass-sandbox)
      ZODIAC_BYPASS_CODEX_SANDBOX=1
      shift
      ;;
    --sandbox)
      ZODIAC_BYPASS_CODEX_SANDBOX=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

export MAX_ANALYZE_REPOS
export PER_PAGE
export MIN_STARS
export MAX_SIZE_KB
export ZODIAC_SKIP_PUBLISH="${ZODIAC_SKIP_PUBLISH:-0}"
export ZODIAC_KEEP_REPOS="${ZODIAC_KEEP_REPOS:-0}"
export ZODIAC_BYPASS_CODEX_SANDBOX="${ZODIAC_BYPASS_CODEX_SANDBOX:-0}"
export ZODIAC_SKIP_ENV_FILE=1

echo "Starting zodiac one-shot run"
echo "  repos: ${MAX_ANALYZE_REPOS}"
echo "  per_page: ${PER_PAGE}"
echo "  min_stars: ${MIN_STARS}"
echo "  max_size_kb: ${MAX_SIZE_KB}"
echo "  publish: $([[ "$ZODIAC_SKIP_PUBLISH" == "1" ]] && echo "no" || echo "env-dependent")"
echo "  keep_repos: ${ZODIAC_KEEP_REPOS}"
echo "  bypass_sandbox: ${ZODIAC_BYPASS_CODEX_SANDBOX}"

cd "$ROOT"
latest_log_before="$(find logs -maxdepth 1 -name 'zodiac-*.log' -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)"

set +e
"$ROOT/scripts/run-cron-cycle.sh"
status=$?
set -e

latest_log_after="$(find logs -maxdepth 1 -name 'zodiac-*.log' -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)"

echo
echo "Zodiac run finished with exit code ${status}"
if [[ -n "$latest_log_after" ]]; then
  echo "  log: ${latest_log_after}"
fi
echo "  prompt packs: $(find prompt-packs -maxdepth 1 -name '*.json' -type f | wc -l)"
echo "  single html: $(find single-html -maxdepth 1 -name '*.html' -type f | wc -l)"

if [[ "$status" -ne 0 ]]; then
  if [[ -n "$latest_log_after" && "$latest_log_after" != "$latest_log_before" ]]; then
    echo
    echo "Last 40 log lines:"
    tail -n 40 "$latest_log_after"
  fi
  exit "$status"
fi
