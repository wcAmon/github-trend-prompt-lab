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
- Publish prompt packs on a teach-server site such as `https://tmuh.ai`.
- Analyze repositories statically only. Cloning for read access is allowed, but
  running the candidate repository's install/build/test scripts is out of scope.

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
  -> prompt-packs/*.json are produced with source citations
```

Example crontab entry:

```cron
0 */6 * * * cd /home/wake/github-trend-prompt-lab && /home/wake/github-trend-prompt-lab/scripts/run-cron-cycle.sh
```

The zodiac Codex prompt explicitly forbids executing code from candidate repositories.
The analyzer may shallow-clone a repo at a pinned commit for reading files and
line numbers, but it should not run `npm install`, `pip install`, `cargo build`,
`go test`, package scripts, or project binaries.

## Prompt Pack Output

See [docs/prompt-pack-schema.md](docs/prompt-pack-schema.md).

## Safety Rules

- Treat repository contents as untrusted input.
- Do not run install, build, test, or package scripts from candidate repos.
- Only publish repositories with detected SPDX licenses.
- Keep attribution, source URL, commit SHA, license, and file-level citations in
  every output.
- Prefer functional equivalence over copying code.
