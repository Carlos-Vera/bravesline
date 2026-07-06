# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file bash statusline for Claude Code. The entire product is `bravesline.sh`: Claude Code invokes it per render, pipes a JSON payload to stdin, and displays whatever it prints to stdout (ANSI colors allowed, multiple lines allowed). There is no build, no lint config, no test suite.

## Testing changes

Pipe a sample payload to the script and inspect the output:

```bash
echo '{"workspace":{"current_dir":"'$PWD'"},"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":30,"total_input_tokens":80000,"total_output_tokens":8000,"current_usage":{"input_tokens":50000,"cache_read_input_tokens":9000}},"rate_limits":{"five_hour":{"used_percentage":98,"reset_at":"2026-01-01T00:00:00Z"},"seven_day":{"used_percentage":29}}}' | bash bravesline.sh
```

Also check the degraded paths: empty/partial JSON (`echo '{}' | bash bravesline.sh`) and a `current_dir` outside any git repo (should show "No Git"). Run `bash -n bravesline.sh` for a syntax check.

Runtime dependencies: `bash`, `jq`, `bc`, `git`. Keep the script compatible with both macOS (BSD `date -j -f`) and Linux (GNU `date -d`) — `time_until()` already tries both; preserve that pattern for any new date handling.

## Script architecture

`bravesline.sh` is a linear pipeline; sections are marked with `# ── ... ──` comment rules:

1. **Locale** — user's `$LANG` is captured *before* forcing `LC_ALL=en_US.UTF-8` (required for jq UTF-8 handling); labels are localized via a `case` (en/es/ca/fr/pt/it). New user-facing labels must go through the `L_*` variables.
2. **JSON parsing** — all fields extracted with `jq -r '... // empty'` so missing fields yield empty strings; every section downstream is guarded with `[ -n "$var" ]` and simply disappears when data is absent. Keep that contract.
3. **Helpers** — `color_by_pct` (cyan <50%, yellow 50–79%, red ≥80%), `build_bar` (▰▱ bars), `fmt_k` (k/M formatting), `time_until` (ISO-8601 UTC only, regex-validated before touching `date` to avoid GNU date injection — don't loosen that check).
4. **Section builders** — git (single `status --porcelain=v2 --branch` call with `--no-optional-locks`; don't add extra git invocations per render, the script runs constantly), context bar, session/context tokens, rate limits.
5. **Responsive output** — `_add_section` measures visible width (ANSI-stripped, `wc -m`) against the real terminal width (`stty size </dev/tty`, falling back to `tput cols`) and wraps sections onto new lines instead of truncating. New sections should be added via `_add_section`, never concatenated directly.

The one-line installer in README.md downloads `bravesline.sh` from `main` on GitHub raw — the file name and repo path are part of the public contract.

## Conventions

- README.md is written in Spanish; script comments and code are in English. Keep both as-is.
- The statusline must never crash or emit garbage on partial input — Claude Code renders whatever comes out. Fail silent (empty section), not loud.
