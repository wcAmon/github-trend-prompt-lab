# GitHub Trend Prompt Lab

Track fast-growing open source GitHub repositories and turn them into
license-aware prompt packs that help agents rebuild functionally equivalent
projects.

The prompt generation agent is named **zodiac**.

This project is intentionally conservative: it does not try to compress a
repository into a prompt that reproduces source verbatim. It captures the
architecture, behavior, file map, build/test flow, and implementation guidance
needed for an agent to rebuild a similar project from scratch.

## MVP Scope

- Discover public, non-fork, non-archived repositories with clear SPDX licenses.
- Snapshot repository metadata daily.
- Rank repositories by recent star/fork velocity and freshness.
- Generate prompt pack records with attribution, license, source commit,
  citations, and rebuild instructions.
- Generate a teach-server-compatible single HTML page for each selected repo.
- Publish the generated HTML pages under the public user `github_trend_lab` on a
  teach-server site such as `https://tmuh.ai`.
- Analyze repositories statically only. Cloning for read access is allowed, but
  running the candidate repository's install/build/test scripts is out of scope.
- Delete temporary repository checkouts after each run. Zodiac uses
  `repos/<timestamp>/` for read-only analysis and the runner removes it on exit.

## Trend Discovery

Use GitHub repository search as the first-stage candidate filter:

```text
is:public fork:false archived:false mirror:false template:false
pushed:>=YYYY-MM-DD stars:>=N size:<MAX_KB license:mit
```

Run one query per accepted license family, store snapshots, and compute your own
trend score from deltas:

```text
trend_score = star_delta_24h * 4 + star_delta_7d + fork_delta_7d * 2 + freshness_bonus
```

The search endpoint can sort by `stars` or `updated`, but "trending" is a delta,
so you need snapshots.

## Quick Start

Set a GitHub token to avoid low unauthenticated limits:

```bash
export GITHUB_TOKEN=ghp_your_token
node scripts/discover-trends.mjs
```

The script prints JSON candidates to stdout. Redirect the output into a snapshot
file if you want to compare it tomorrow:

```bash
node scripts/discover-trends.mjs > snapshots/$(date +%F).json
```

## Local Cron + Codex CLI

The intended automation model is local cron starting Codex CLI:

```text
cron
  -> scripts/run-cron-cycle.sh
  -> scripts/discover-trends.mjs
  -> zodiac runs through `codex exec`, reads the snapshot, and statically analyzes selected repos
  -> prompt-packs/*.json and single-html/*.html are produced with source citations
  -> optional publish step uploads single-html pages to teach-server
```

Example crontab entry:

```cron
0 */6 * * * cd /home/wake/github-trend-prompt-lab && /home/wake/github-trend-prompt-lab/scripts/run-cron-cycle.sh
```

The zodiac Codex prompt explicitly forbids executing code from candidate repositories.
The analyzer may shallow-clone a repo at a pinned commit for reading files and
line numbers, but it should not run `npm install`, `pip install`, `cargo build`,
`go test`, package scripts, or project binaries. The runner deletes the
run-specific checkout directory after analysis; set `ZODIAC_KEEP_REPOS=1` only
when debugging a failed run.

Run zodiac once by hand:

```bash
./run_zodiac.sh
```

Useful manual options:

```bash
./run_zodiac.sh --repos 1 --no-publish
./run_zodiac.sh --repos 1 --bypass-sandbox
./run_zodiac.sh --repos 1 --keep-repos
```

Publishing uses a stable slug derived from `<owner>--<repo>` with a hash suffix
for long names, so seeing the same repository again updates the existing
`github_trend_lab` page instead of creating a duplicate page.

## Prompt Pack Output

See [docs/prompt-pack-schema.md](docs/prompt-pack-schema.md).

Each generated repo page has three visible documents:

1. Why this repo is becoming a trend.
2. Where this repo can be applied.
3. Rebuild prompt.

## Safety Rules

- Treat repository contents as untrusted input.
- Do not run install, build, test, or package scripts from candidate repos.
- Only publish repositories with detected SPDX licenses.
- Keep attribution, source URL, commit SHA, license, and file-level citations in
  every output.
- Prefer functional equivalence over copying code.
