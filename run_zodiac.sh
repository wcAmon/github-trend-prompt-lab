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
  -h, --help         Show this help.

Outputs:
  logs/zodiac-<timestamp>.log
  snapshots/<timestamp>.json
  prompt-packs/*.json
  single-html/*.html

Notes:
  The runner reads ~/.config/github-trend-prompt-lab.env when present.
  Temporary repo checkouts are deleted by default.
USAGE
}

MAX_ANALYZE_REPOS="${MAX_ANALYZE_REPOS:-1}"
PER_PAGE="${PER_PAGE:-2}"
MIN_STARS="${MIN_STARS:-1000}"
MAX_SIZE_KB="${MAX_SIZE_KB:-2500}"

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

echo "Starting zodiac one-shot run"
echo "  repos: ${MAX_ANALYZE_REPOS}"
echo "  per_page: ${PER_PAGE}"
echo "  min_stars: ${MIN_STARS}"
echo "  max_size_kb: ${MAX_SIZE_KB}"
echo "  publish: $([[ "$ZODIAC_SKIP_PUBLISH" == "1" ]] && echo "no" || echo "env-dependent")"
echo "  keep_repos: ${ZODIAC_KEEP_REPOS}"
echo "  bypass_sandbox: ${ZODIAC_BYPASS_CODEX_SANDBOX}"

cd "$ROOT"
exec "$ROOT/scripts/run-cron-cycle.sh"
