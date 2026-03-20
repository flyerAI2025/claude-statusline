#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# claude-statusline
# Batteries-included status line for Claude Code
# Pure bash + jq · macOS · One file · Copy → done
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Config ───────────────────────────────────────────────
: "${CSL_SEP:=│}"
: "${CSL_SHOW_CWD:=0}"
: "${CSL_SHOW_GIT:=0}"
: "${CSL_SHOW_SESSION:=1}"
: "${CSL_SHOW_MODEL:=1}"
: "${CSL_SHOW_EFFORT:=1}"
: "${CSL_SHOW_CONTEXT:=1}"
: "${CSL_SHOW_STYLE:=1}"
: "${CSL_SHOW_COST:=1}"
: "${CSL_SHOW_LINES:=0}"
: "${CSL_SHOW_DURATION:=0}"
: "${CSL_SHOW_USAGE:=1}"
: "${CSL_SHOW_PACING:=1}"
: "${CSL_SHOW_CPU:=1}"
: "${CSL_SHOW_MEM:=1}"
: "${CSL_SHOW_TIME:=1}"

# ── Colors ───────────────────────────────────────────────
# 4-color rotation: all bold for light & dark theme readability
# Adjacent items always use different colors from this palette
R='\033[0m'
BRED='\033[1;31m' BYLW='\033[1;33m' GRY='\033[90m'
C1='\033[1;32m'   # Bold Green
C2='\033[1;35m'   # Bold Magenta
C3='\033[1;34m'   # Bold Blue
C4='\033[1;36m'   # Bold Cyan

command -v jq &>/dev/null || { printf "${BRED}jq required${R}\n"; exit 0; }
# Compute epoch and HH:MM in one date call
_d=$(date '+%s %H:%M'); NOW=${_d% *}; NOW_TIME=${_d#* }

# ── Helpers ──────────────────────────────────────────────
# Dynamic color: sets global _CLR; ok=base, warning=yellow, critical=red
_clr() {
  local p=$1 lo=${3:-50} hi=${4:-80}
  if   [ "$p" -ge "$hi" ] 2>/dev/null; then _CLR=$BRED
  elif [ "$p" -ge "$lo" ] 2>/dev/null; then _CLR=$BYLW
  else _CLR=$2; fi
}
_dur() {
  local ms=$1; [ -z "$ms" ] && return; local s=$(( ${ms%.*} / 1000 ))
  if   [ "$s" -lt 60 ];   then printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '%dm' $(( s / 60 ))
  else printf '%dh%dm' $(( s / 3600 )) $(( s % 3600 / 60 )); fi
}
# Rate alert: shows ! when consuming faster than sustainable pace
_pace() {
  [ "$CSL_SHOW_PACING" != "1" ] && return
  local ep=$1 win=$2 ut=$3; [ -z "$ep" ] || [ -z "$ut" ] && return
  local rem=$(( ep - NOW ))
  [ "$rem" -le 0 ] && return
  local el=$(( win - rem )) u=${ut%.*}; [ "$el" -le 0 ] && return
  local exp=$(( el * 100 / win ))
  [ "$u" -gt $(( exp + 15 )) ] 2>/dev/null && printf '%s' "${BRED}!"
}
# Usage segment: "label:pct%[!][@time]" — sets global _USEG
_usage_seg() {
  local val=$1 label=$2 color=$3 ep=$4 win=$5 fmt=$6
  local p=${val%.*} t=""
  [ -n "$ep" ] && t=$(date -r "$ep" "+$fmt" 2>/dev/null)
  _clr "$p" "$color"
  _USEG="${_CLR}${label}:${p}%$(_pace "$ep" "$win" "$val")"
  [ -n "$t" ] && _USEG="${_USEG}${GRY}@${t}"
}

# ── Parse JSON (single jq call) ─────────────────────────
input=$(cat)
IFS=$'\x1e' read -r cwd model used_pct ctx_size vim_mode \
  session_name cost_usd output_style duration_ms \
  lines_add lines_del _5h _5r _7d _7r <<< "$(jq -r '
  def sp: gsub(" "; "·");
  def n: if . == null then "" else tostring end;
  [(.workspace.current_dir // .cwd // ""), ((.model.display_name // "")|sp),
   (.context_window.used_percentage|n), (.context_window.context_window_size|n),
   (.vim.mode // ""), (.session_name // ""), (.cost.total_cost_usd|n),
   (.output_style.name // ""), (.cost.total_duration_ms|n),
   (.cost.total_lines_added|n), (.cost.total_lines_removed|n),
   (.rate_limits.five_hour.used_percentage|n),
   (.rate_limits.five_hour.resets_at|n),
   (.rate_limits.seven_day.used_percentage|n),
   (.rate_limits.seven_day.resets_at|n)
  ] | join("\u001e")' <<< "$input" 2>/dev/null)"

# Effort level: not in statusline JSON, read from settings
effort=""
[ "$CSL_SHOW_EFFORT" = "1" ] && \
  effort=$(awk -F'"' '/effortLevel/{print $4}' "$HOME/.claude/settings.json" 2>/dev/null)

# ── Git ──────────────────────────────────────────────────
git_branch=""
if [ "$CSL_SHOW_GIT" = "1" ] && [ -n "$cwd" ]; then
  export GIT_OPTIONAL_LOCKS=0
  git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$git_branch" = "HEAD" ] && \
    git_branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ── System stats ─────────────────────────────────────────
cpu= mem_u=
[ "$CSL_SHOW_CPU" = "1" ] && {
  : "${CSL_NCPU:=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)}"
  cpu=$(ps -A -o %cpu 2>/dev/null | awk -v n="$CSL_NCPU" '{s+=$1} END{printf "%.0f",s/n}')
}
[ "$CSL_SHOW_MEM" = "1" ] && {
  mem_u=$(vm_stat 2>/dev/null | awk '
    /Pages active/{a=$NF}/Pages wired/{w=$NF}/Pages compressed/{c=$NF}/Pages speculative/{sp=$NF}
    END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",c);gsub(/\./,"",sp)
        printf "%.1f",(a+w+c+sp)*4096/1073741824}')
  : "${CSL_MEMTOTAL:=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f",$1/1073741824}')}"
}

# ── Build output ─────────────────────────────────────────
# Color rotation: C1(green) C2(magenta) C3(blue) C4(cyan)
# ensures every adjacent item has a distinct hue
parts=()
s="${GRY}${CSL_SEP}${R}"

# CWD [C3 Bold Blue] (off by default)
[ "$CSL_SHOW_CWD" = "1" ] && \
  parts+=("${C3}${cwd/#$HOME/~}${R}")

# Git [C1 Bold Green]
[ "$CSL_SHOW_GIT" = "1" ] && [ -n "$git_branch" ] && \
  parts+=("${C1}${git_branch}${R}")

# Session [C4 Bold Cyan]
[ "$CSL_SHOW_SESSION" = "1" ] && [ -n "$session_name" ] && \
  parts+=("${C4}${session_name}${R}")

# Model [C2 Bold Magenta]
[ "$CSL_SHOW_MODEL" = "1" ] && [ -n "$model" ] && \
  parts+=("${C2}${model}${R}")

# Effort [C1 Bold Green]
if [ "$CSL_SHOW_EFFORT" = "1" ] && [ -n "$effort" ]; then
  case "$effort" in [Hh]*) _ef="H" ;; [Mm]*) _ef="M" ;; [Ll]*) _ef="L" ;; *) _ef="$effort" ;; esac
  parts+=("${C1}${_ef}${R}")
fi

# Context [C3 Bold Blue → Yellow → Red]
if [ "$CSL_SHOW_CONTEXT" = "1" ] && [ -n "$used_pct" ] && [ -n "$ctx_size" ]; then
  p=${used_pct%.*}; uk=$(( ctx_size * p / 100 / 1000 )); tk=$(( ctx_size / 1000 ))
  _clr "$p" "$C3"; parts+=("${_CLR}${uk}k/${tk}k(${p}%)${R}")
fi

# Output style [C1 Bold Green] (non-default only)
if [ "$CSL_SHOW_STYLE" = "1" ] && [ -n "$output_style" ]; then
  case "$output_style" in [Dd]efault) ;; *) parts+=("${C1}[${output_style}]${R}") ;; esac
fi

# Cost [C4 Bold Cyan → Yellow → Red]
if [ "$CSL_SHOW_COST" = "1" ] && [ -n "$cost_usd" ]; then
  cf=$(printf '%.2f' "$cost_usd"); ci=${cf%.*}
  _clr "$ci" "$C4" 1 5; parts+=("${_CLR}\$${cf}${R}")
fi

# Lines [C2 Bold Magenta / Bold Red] (off by default)
if [ "$CSL_SHOW_LINES" = "1" ]; then
  la=${lines_add:-0}; ld=${lines_del:-0}
  if [ "$la" != "0" ] || [ "$ld" != "0" ]; then
    lc=""
    [ "$la" != "0" ] && lc="${C2}+${la}"
    [ "$ld" != "0" ] && lc="${lc}${BRED}-${ld}"
    parts+=("${lc}${R}")
  fi
fi

# Duration [C3 Bold Blue] (off by default)
[ "$CSL_SHOW_DURATION" = "1" ] && [ -n "$duration_ms" ] && {
  d=$(_dur "$duration_ms")
  [ -n "$d" ] && parts+=("${C3}${d}${R}")
}

# 5h quota [C1 Bold Green → Yellow → Red]
# 7d quota [C2 Bold Magenta → Yellow → Red]
if [ "$CSL_SHOW_USAGE" = "1" ] && { [ -n "$_5h" ] || [ -n "$_7d" ]; }; then
  u=""
  if [ -n "$_5h" ]; then
    _usage_seg "$_5h" "5h" "$C1" "$_5r" 18000 '%H:%M'
    u="$_USEG"
  fi
  if [ -n "$_7d" ]; then
    [ -n "$u" ] && u="${u}${R}${s}"
    _usage_seg "$_7d" "7d" "$C2" "$_7r" 604800 '%m/%d·%H:%M'
    u="${u}${_USEG}"
  fi
  parts+=("${u}${R}")
fi

# CPU [C3 Bold Blue → Yellow → Red]
if [ "$CSL_SHOW_CPU" = "1" ] && [ -n "$cpu" ]; then
  _clr "$cpu" "$C3"; parts+=("${_CLR}cpu:${cpu}%${R}")
fi

# Memory [C4 Bold Cyan]
[ "$CSL_SHOW_MEM" = "1" ] && [ -n "$mem_u" ] && [ -n "$CSL_MEMTOTAL" ] && \
  parts+=("${C4}${mem_u}/${CSL_MEMTOTAL}G${R}")

# Time [C1 Bold Green] — computed alongside $NOW at startup, no extra date call
[ "$CSL_SHOW_TIME" = "1" ] && parts+=("${C1}${NOW_TIME}${R}")

# Vim mode [C2 Bold Magenta / C1 Bold Green]
[ -n "$vim_mode" ] && {
  [ "$vim_mode" = "NORMAL" ] && parts+=("${C2}[N]${R}") \
    || parts+=("${C1}[I]${R}")
}

# ── Join & print ─────────────────────────────────────────
line=""
for part in "${parts[@]}"; do
  [ -z "$line" ] && line="$part" || line="${line}${s}${part}"
done
printf '%b\n' "$line"
