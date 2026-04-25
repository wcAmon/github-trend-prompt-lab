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

## Static-Only Policy

The automated Codex job is for analysis and prompt-pack generation only.

Allowed:

- GitHub API reads.
- Shallow clone at a pinned commit for reading files.
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
