# bravesline

A statusline for [Claude Code](https://claude.ai/code) that shows useful coding context directly in your terminal.

```
myapp (main ↑2 +3 ~1) | Claude Sonnet 4.6 | cntxto:[████████░░░░░░░░░░░░] 40% usado ses:5.2k(3.1ktok) | 5h:[████░░░░░░] 40% 7d:[██░░░░░░░░] 20%
```

## Features

- **Git** — branch, ahead/behind remote, staged/unstaged/untracked counts, stash count
- **Context window** — visual bar with color coding (cyan → yellow → red), usage %, session tokens, current context tokens
- **Rate limits** — 5-hour and 7-day usage bars with reset countdown
- **No Git** — shows `No Git` when outside a repository
- **Multi-language** — labels adapt to your system locale: `en`, `es`/`ca`, `fr`, `pt`, `it`

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `bash`, `jq`, `bc`, `git`

## Install

```bash
F=~/.claude/settings.json; [ -f "$F" ] || echo '{}' > "$F"; \
curl -fsSL https://raw.githubusercontent.com/Carlos-Vera/bravesline/main/bravesline.sh \
  -o ~/.claude/bravesline.sh && \
jq '.statusLine = {"type":"command","command":"bash ~/.claude/bravesline.sh","padding":0}' \
  "$F" > /tmp/_bl.json && mv /tmp/_bl.json "$F"
```

Restart Claude Code and the statusline will appear immediately.

## What each section shows

| Section | Info |
|---|---|
| `folder (branch)` | Current directory and git branch |
| `↑N ↓N` | Commits ahead / behind remote |
| `+N ~N ?N` | Staged / modified / untracked files |
| `≡N` | Stash entries |
| `ctx/cntxto:[bar] N%` | Context window usage |
| `ses:Nk` | Total session tokens (input + output) |
| `(Nktok)` | Tokens currently in context |
| `5h:[bar]` | Rate limit usage for the 5-hour window |
| `7d:[bar]` | Rate limit usage for the 7-day window |
| `↺Xh Ym` | Time until rate limit resets |

## Color coding

| Color | Meaning |
|---|---|
| Cyan / Green | Under 50% — all good |
| Yellow | 50–79% — getting there |
| Red | 80%+ — watch out |

---

Developed for the community by [Carlos Vera](mailto:carlos@braveslab.com) · [BravesLab](https://braveslab.com)  
*All glory to my Father, Jesus Christ*
