# Local Cron Automation

This project is designed to run from the host machine with cron. Cron starts a
small shell runner; the runner captures a GitHub trend snapshot and then starts
Codex CLI in non-interactive mode. The prompt generation agent is named
**zodiac**.

## Environment

Create a local environment file that is not committed:

```bash
mkdir -p ~/.config
$EDITOR ~/.config/github-trend-prompt-lab.env
```

Example:

```bash
export GITHUB_TOKEN=ghp_your_token
export CODEX_BIN=/home/wake/.nvm/versions/node/v24.15.0/bin/codex
export CODEX_MODEL=gpt-5.2
export MAX_ANALYZE_REPOS=3
export ZODIAC_TEACH_SERVER_BASE_URL=https://tmuh.ai
export ZODIAC_TEACH_SERVER_API_KEY=tk_your_github_trend_lab_key
```

By default, every run deletes its temporary checkout directory after zodiac
finishes or fails. Set this only when debugging:

```bash
export ZODIAC_KEEP_REPOS=1
```

If Codex's local sandbox cannot start on the host, the log may contain:

```text
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
```

The runner supports an explicit escape hatch:

```bash
export ZODIAC_BYPASS_CODEX_SANDBOX=1
```

Use that only on a machine where you accept that Codex can run without its own
sandbox. The zodiac prompt still forbids executing candidate repository code,
but this setting removes the CLI sandbox enforcement layer.

## Crontab

Run every six hours:

```cron
0 */6 * * * cd /home/wake/github-trend-prompt-lab && /home/wake/github-trend-prompt-lab/scripts/run-cron-cycle.sh
```

Check logs:

```bash
ls -lt /home/wake/github-trend-prompt-lab/logs/zodiac-*.log
```

## Manual Run

Run zodiac once with conservative defaults:

```bash
cd /home/wake/github-trend-prompt-lab
./run_zodiac.sh
```

The manual runner prints a compact summary when it exits, including the latest
log path and generated file counts. On failure, it also prints the last 40 log
lines so sandbox or API errors are visible immediately.

Common one-shot variants:

```bash
./run_zodiac.sh --repos 1 --no-publish
./run_zodiac.sh --repos 1 --bypass-sandbox
./run_zodiac.sh --repos 1 --keep-repos
```

Duplicate repository handling is intentionally update-based. The generated
single HTML filename and publish slug are derived from `<owner>--<repo>`, so a
later zodiac run for the same repository overwrites the existing local HTML and
updates the existing `github_trend_lab` hosted page. Very long repo names use a
stable hash suffix in the slug to avoid collisions.

## Static-Only Policy

The automated Codex job is for analysis and prompt-pack generation only.

Allowed:

- GitHub API reads.
- Shallow clone at a pinned commit for reading files.
- Temporary checkouts under `repos/<timestamp>/`; the runner deletes them on
  exit unless `ZODIAC_KEEP_REPOS=1` is set.
- Reading README, license, manifests, configs, source files, tests, and CI files.
- Producing cited prompt pack JSON.

Forbidden:

- Running install scripts from candidate repositories.
- Running build scripts from candidate repositories.
- Running candidate test suites.
- Running binaries, package scripts, Makefiles, or shell scripts from candidate
  repositories.

Verification of rebuilt projects should be a separate, explicitly sandboxed
phase after the prompt pack exists.

## Publishing

When `ZODIAC_TEACH_SERVER_API_KEY` is set, the runner uploads generated
`single-html/*.html` files to teach-server using the same `POST /api/pages`
endpoint as normal users. The API key should belong to the public
`github_trend_lab` user.

The public read-only dashboard is:

```text
https://tmuh.ai/u/github_trend_lab/
```
