#!/usr/bin/env bash
# DEV + MARKETING + IA  ===========================================================
#
#  :+++;
#  ;&&&&.
#  ;&&&&.
#  ;&&&&. :;++;.       :::::  :;+       .::::       .::::.       .:::.      :;++;:          .:++x+:.
#  ;&&&&$&&&&&&&&$:    +&&&X$&&&$        $&&&&.      $&&&&      .&&&&:   +&&&&&&&&&&;    :X&&&&&&&&&&X
#  ;&&&&&&X++X&&&&&+   +&&&&&&&$$        :&&&&X      :&&&&$.     ;&&;  :&&&&&;;;+&&&&$.  &&&&X;;;;+$x
#  ;&&&&X      X&&&&:  +&&&&X             ;&&&&+      ;&&&&+      xx   &&&&+      x&&&x .&&&&X:
#  ;&&&&       .&&&&;  +&&&&               x&&&&;      +&&&&;         :&&&&XX&&&&&&&&&$  +&&&&&&&&&$+
#  ;&&&&:      :&&&&:  +&&&&        .;      $&&&&.     .$&&&&:        .&&&&&$X++:          .;+x$&&&&&&:
#  ;&&&&&+   .+&&&&$.  +&&&&       .$$.     :&&&&&.      $&&&$         +&&&&+.    ;+:    :;:      $&&&;
#  ;&&&&&&&&&&&&&&X    +&&&&       X&&$      ;&&&&x      ;&&&&X         ;&&&&&&&&&&&&x  .&&&&&&&&&&&&X.
#  :$&&$.x$&&&&$+      +&&&X      +$$$$       +$$$$;      +$$$$:          .X$&&&&&$X:    ;X$&&&&&&$x.
#
#  =====================================================================================    L    A    B
#
#  Statusline v2 — developed for the community by Carlos Vera
#  carlos@braveslab.com | All glory to my Father, Jesus Christ
#  =================================================================================

# Save user locale BEFORE overriding for jq UTF-8 compatibility
_user_lang="${LANG:-${LC_ALL:-}}"
_user_lang=$(echo "$_user_lang" | cut -d_ -f1 | cut -d. -f1 | tr '[:upper:]' '[:lower:]' 2>/dev/null)
[ -z "$_user_lang" ] && _user_lang="en"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ── Localized labels ──────────────────────────────────────────────────────────
case "$_user_lang" in
  es|ca) L_CTX="cntxto" L_USED="usado"  L_SESSION="ses" L_TOKENS="tok" L_STASH="≡" L_STAGED="+" L_MOD="~" L_NEW="?" ;;
  fr)    L_CTX="ctx"    L_USED="util."  L_SESSION="ses" L_TOKENS="tok" L_STASH="≡" L_STAGED="+" L_MOD="~" L_NEW="?" ;;
  pt)    L_CTX="ctx"    L_USED="usado"  L_SESSION="ses" L_TOKENS="tok" L_STASH="≡" L_STAGED="+" L_MOD="~" L_NEW="?" ;;
  it)    L_CTX="ctx"    L_USED="usato"  L_SESSION="ses" L_TOKENS="tok" L_STASH="≡" L_STAGED="+" L_MOD="~" L_NEW="?" ;;
  *)     L_CTX="ctx"    L_USED="used"   L_SESSION="ses" L_TOKENS="tok" L_STASH="≡" L_STAGED="+" L_MOD="~" L_NEW="?" ;;
esac

# ── Parse JSON input ──────────────────────────────────────────────────────────
input=$(cat)

cwd=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // empty')
folder=$(basename "${cwd:-.}")
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '
  (.context_window.current_usage.input_tokens // 0) +
  (.context_window.current_usage.cache_creation_input_tokens // 0) +
  (.context_window.current_usage.cache_read_input_tokens // 0)
  | if . == 0 then empty else tostring end')
session_tokens=$(echo "$input" | jq -r '
  ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))
  | if . == 0 then empty else tostring end')

five_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage  // empty')
week_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage  // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.reset_at         // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.reset_at         // empty')

# ── Colors ────────────────────────────────────────────────────────────────────
_blue=$'\033[0;34m'
_magenta=$'\033[0;35m'
_yellow=$'\033[0;33m'
_cyan=$'\033[0;36m'
_green=$'\033[0;32m'
_red=$'\033[0;31m'
_dim=$'\033[2m'
_reset=$'\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
color_by_pct() {
  local pct_int=$(printf "%.0f" "${1:-0}" 2>/dev/null || echo 0)
  if   [ "$pct_int" -ge 80 ]; then printf '%s' "$_red"
  elif [ "$pct_int" -ge 50 ]; then printf '%s' "$_yellow"
  else printf '%s' "$_cyan"
  fi
}

build_bar() {
  local pct="$1" total="${2:-10}"
  local step; step=$(echo "100 / $total" | bc -l)
  local filled=$(printf "%.0f" "$(echo "$pct / $step" | bc -l)" 2>/dev/null || echo 0)
  [ "$filled" -gt "$total" ] && filled=$total
  local empty=$(( total - filled ))
  local bar="" i=0
  while [ $i -lt $filled ]; do bar="${bar}▰"; i=$((i+1)); done
  i=0
  while [ $i -lt $empty  ]; do bar="${bar}▱"; i=$((i+1)); done
  printf '%s' "$bar"
}

fmt_k() {
  local n="${1:-0}"
  if   [ "$n" -ge 1000000 ] 2>/dev/null; then printf "%.1fM" "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000    ] 2>/dev/null; then printf "%.1fk" "$(echo "$n / 1000"    | bc -l)"
  else printf '%s' "$n"
  fi
}

# Returns "Xh Ym" until an ISO-8601 UTC timestamp, empty if not parseable/past
time_until() {
  local ts="$1"
  [ -z "$ts" ] && return
  # Validate strict ISO-8601 UTC format before passing to date (avoids GNU date command injection)
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || return
  local now target diff
  now=$(date +%s)
  # Try macOS date first, then GNU date
  target=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null) \
    || target=$(date -d "$ts" +%s 2>/dev/null)
  [ -z "$target" ] && return
  diff=$(( target - now ))
  [ "$diff" -le 0 ] && return
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  [ "$h" -gt 0 ] && printf "%dh%02dm" "$h" "$m" || printf "%dm" "$m"
}

# ── Git info (single status call) ─────────────────────────────────────────────
branch_part=""
if [ -n "$cwd" ]; then
  git_status=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)

  if [ -n "$git_status" ]; then
    branch=$(printf '%s' "$git_status" | awk '/^# branch.head/{print $3}')
    [ "$branch" = "(detached)" ] && branch="HEAD"

    # Truncate long branch names
    [ "${#branch}" -gt 28 ] && branch="${branch:0:25}…"

    ab_line=$(printf '%s' "$git_status" | grep "^# branch.ab" || true)
    ahead=$(printf '%s' "$ab_line"  | grep -oE '\+[0-9]+' | tr -d '+')
    behind=$(printf '%s' "$ab_line" | grep -oE '\-[0-9]+'  | tr -d '-')

    # Dirty indicator
    dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    stash_count=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')

    extras=""
    [ "${ahead:-0}"       -gt 0 ] && extras="${extras} ${_green}↑${ahead}${_reset}"
    [ "${behind:-0}"      -gt 0 ] && extras="${extras} ${_red}↓${behind}${_reset}"
    [ "${stash_count:-0}" -gt 0 ] && extras="${extras} ${_cyan}${L_STASH}${stash_count}${_reset}"
    if [ -n "$dirty" ]; then
      dirty_count=$(printf '%s' "$dirty" | grep -c .)
      branch_color=$_red
      extras="${extras} ↑${dirty_count} ●"
    else
      branch_color=$_green
      extras="${extras} ●"
    fi

    branch_part="${branch_color}${branch}${extras}${_reset}"
  else
    branch_part="${_dim}No Git${_reset}"
  fi
fi

# ── Context window ────────────────────────────────────────────────────────────
ctx_part=""
sess_part=""
tok_part=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar=$(build_bar "$used" 20)
  color=$(color_by_pct "$used_int")
  ctx_part="${L_CTX}:${color}${bar}${_reset} ${used_int}%"
fi

if [ -n "$session_tokens" ]; then
  sess_fmt=$(fmt_k "$session_tokens")
  sess_part="${_dim}${L_USED}${_reset} ${_green}${L_SESSION}:${sess_fmt}${_reset}"
fi

if [ -n "$input_tokens" ]; then
  tok_fmt=$(fmt_k "$input_tokens")
  tok_part="${_dim}Total${_reset} ${tok_fmt} ${_dim}${L_TOKENS}${_reset}"
fi

# ── Rate limits ───────────────────────────────────────────────────────────────
rate_part=""

if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  five_bar=$(build_bar "$five_pct" 10)
  five_color=$(color_by_pct "$five_int")
  reset_str=$(time_until "$five_reset")
  [ -n "$reset_str" ] && reset_label=" ${_dim}↺${reset_str}${_reset}" || reset_label=""
  rate_part="${rate_part}5h:${five_color}${five_bar}${_reset} ${five_int}%${reset_label}"
fi

if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  week_bar=$(build_bar "$week_pct" 10)
  if   [ "$week_int" -ge 80 ]; then week_color=$_red
  elif [ "$week_int" -ge 50 ]; then week_color=$_yellow
  else                               week_color=$_green
  fi
  reset_str=$(time_until "$week_reset")
  [ -n "$reset_str" ] && reset_label=" ${_dim}↺${reset_str}${_reset}" || reset_label=""
  [ -n "$rate_part" ] && rate_part="${rate_part} "
  rate_part="${rate_part}7d:${week_color}${week_bar}${_reset} ${week_int}%${reset_label}"
fi

# ── Final output ──────────────────────────────────────────────────────────────
SEP="${_dim} ❯ ${_reset}"

# Visible length: strip ANSI codes and count characters (UTF-8 aware)
_vlen() { printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g' | wc -m | tr -d ' \t\n'; }

# Terminal width — stty reads from the actual TTY even in subprocesses
_cols=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
[ -z "$_cols" ] || [ "$_cols" -le 0 ] && _cols=$(tput cols 2>/dev/null)
[ -z "$_cols" ] || [ "$_cols" -le 0 ] && _cols=9999

# Multi-line builder: wraps to a new line when a section doesn't fit
_lines=("${_blue}${folder}${_reset}${SEP}${_magenta}${model}${_reset}")
_cur=0

_add_section() {
  local _sec="$1"
  local _candidate="${_lines[$_cur]}${SEP}${_sec}"
  if [ "$(_vlen "$_candidate")" -le "$_cols" ]; then
    _lines[$_cur]="$_candidate"
  else
    _cur=$((_cur + 1))
    _lines[$_cur]="$_sec"
  fi
}

[ -n "$branch_part" ] && _add_section "$branch_part"
[ -n "$ctx_part"    ] && _add_section "$ctx_part"
[ -n "$rate_part"   ] && _add_section "$rate_part"
[ -n "$sess_part"   ] && _add_section "$sess_part"
[ -n "$tok_part"    ] && _add_section "$tok_part"

# Output all lines joined with newline (no trailing newline on last)
_out=""
for _i in "${!_lines[@]}"; do
  [ "$_i" -gt 0 ] && _out="${_out}"$'\n'
  _out="${_out}${_lines[$_i]}"
done
printf "%s" "$_out"
