#!/bin/bash

input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "~"')

# Display path relative to home if inside home, otherwise full path
home="$HOME"
if [[ "$cwd" == "$home" ]]; then
  dir="~"
elif [[ "$cwd" == "$home"/* ]]; then
  dir="~${cwd#$home}"
else
  dir="$cwd"
fi

# OS icon (macOS Apple logo)
os_icon=$(printf '\xef\xa3\xbf')

# Git info - matching P10k style
git_parts=()
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
  git_parts+=("$branch")

  # Dirty/clean status
  if [[ -z $(git -C "$cwd" status --porcelain 2>/dev/null) ]]; then
    git_clean=true
  else
    git_clean=false
    modified_count=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    git_parts+=("~$modified_count")
  fi

  # Ahead/behind
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    ahead_behind=""
    [ "$ahead" -gt 0 ] && ahead_behind+="↑$ahead"
    [ "$behind" -gt 0 ] && ahead_behind+="↓$behind"
    [ -n "$ahead_behind" ] && git_parts+=("$ahead_behind")
  fi

  # Stash count
  stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  [ "$stash_count" -gt 0 ] && git_parts+=("$(printf '\xef\x81\x9c')$stash_count")

  git_display="${git_parts[*]}"
else
  git_display=""
  git_clean=""
fi

# Model name
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""' | sed 's/Claude //' | sed 's/ /-/g')

# Context usage (percent until auto-compacting)
# Current context = cache_read + cache_creation + current input/output
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cur_in=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cur_out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
context_max=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
context_used=$((cache_read + cache_create + cur_in + cur_out))
if [ "$context_max" -gt 0 ] 2>/dev/null; then
  context_pct=$((context_used * 100 / context_max))
else
  context_pct=0
fi

# Session duration
duration=$(echo "$input" | jq '.cost.total_duration_ms // 0')
duration_min=$((duration / 60000))

# Overall usage from Anthropic API (cached for 60 seconds)
usage_cache="$HOME/.claude/usage-cache.json"
cache_max_age=60

# Check if cache exists and is fresh
if [ -f "$usage_cache" ]; then
  cache_age=$(($(date +%s) - $(stat -f %m "$usage_cache" 2>/dev/null || echo 0)))
else
  cache_age=999999
fi

if [ "$cache_age" -gt "$cache_max_age" ]; then
  # Fetch fresh usage data
  creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  if [ -n "$creds" ]; then
    token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -n "$token" ]; then
      curl -s -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" > "$usage_cache" 2>/dev/null
    fi
  fi
fi

# Read usage from cache
if [ -f "$usage_cache" ]; then
  five_hr=$(jq -r '.five_hour.utilization // 0' "$usage_cache" 2>/dev/null)
  seven_day=$(jq -r '.seven_day.utilization // 0' "$usage_cache" 2>/dev/null)
  five_hr_int=${five_hr%.*}
  seven_day_int=${seven_day%.*}
  # Ensure we have valid integers
  five_hr_int=${five_hr_int:-0}
  seven_day_int=${seven_day_int:-0}
else
  five_hr_int=0
  seven_day_int=0
fi

# Conda environment (matching P10k anaconda segment)
conda_env=""
if [ -n "$CONDA_DEFAULT_ENV" ]; then
  conda_env="$(printf '\xee\x9c\xbc') $CONDA_DEFAULT_ENV"
fi

# NVM/Node version (matching P10k nvm segment)
node_version=""
if [ -f "$cwd/package.json" ]; then
  if command -v node &> /dev/null; then
    node_ver=$(node --version 2>&1 | sed 's/v//')
    node_version="$(printf '\xee\x9c\x98') $node_ver"
  fi
fi

# Virtual environment (matching P10k virtualenv segment)
venv=""
if [ -n "$VIRTUAL_ENV" ]; then
  venv="$(printf '\xee\x9c\xbc') $(basename "$VIRTUAL_ENV")"
fi

# Context (user@hostname - matching P10k context segment)
context="$(whoami)@$(hostname -s)"

# Build output using printf for proper color handling
# Left side: OS icon, directory, git status
printf '\033[0;37m%s\033[0m  \033[0;36m%s\033[0m' "$os_icon" "$dir"

# Git status with color
if [ -n "$git_display" ]; then
  printf '  \033[0;35m%s\033[0m' "$(printf '\xee\x82\xa0') $git_display"
  if [ "$git_clean" = true ]; then
    printf ' \033[0;32m✓\033[0m'
  elif [ "$git_clean" = false ]; then
    printf ' \033[0;31m✗\033[0m'
  fi
fi

# Right side segments with separators
printf '  \033[0;90m│\033[0m  \033[0;34m%s\033[0m' "$model"

# Session duration
if [ "$duration_min" -gt 0 ]; then
  printf '  \033[0;90m│\033[0m  \033[0;90m%s %dm\033[0m' "$(printf '\xef\x80\x97')" "$duration_min"
fi

# Usage with color coding
printf '  \033[0;90m│\033[0m  %s ' "$(printf '\xef\x82\xa0')"
if [ "$five_hr_int" -ge 80 ] 2>/dev/null; then
  printf '\033[0;31m\033[1m5h:%d%%\033[0m' "$five_hr_int"
elif [ "$five_hr_int" -ge 50 ] 2>/dev/null; then
  printf '\033[0;33m5h:%d%%\033[0m' "$five_hr_int"
else
  printf '\033[0;32m5h:%d%%\033[0m' "$five_hr_int"
fi

printf ' '

if [ "$seven_day_int" -ge 80 ] 2>/dev/null; then
  printf '\033[0;31m\033[1m7d:%d%%\033[0m' "$seven_day_int"
elif [ "$seven_day_int" -ge 50 ] 2>/dev/null; then
  printf '\033[0;33m7d:%d%%\033[0m' "$seven_day_int"
else
  printf '\033[0;32m7d:%d%%\033[0m' "$seven_day_int"
fi

# Context usage (percent until compacting)
printf '  \033[0;90m│\033[0m  '
if [ "$context_pct" -ge 80 ] 2>/dev/null; then
  printf '\033[0;31m\033[1mctx:%d%%\033[0m' "$context_pct"
elif [ "$context_pct" -ge 50 ] 2>/dev/null; then
  printf '\033[0;33mctx:%d%%\033[0m' "$context_pct"
else
  printf '\033[0;32mctx:%d%%\033[0m' "$context_pct"
fi

# Environment indicators
[ -n "$conda_env" ] && printf '  \033[0;90m│\033[0m  \033[0;33m%s\033[0m' "$conda_env"
[ -n "$venv" ] && printf '  \033[0;90m│\033[0m  \033[0;33m%s\033[0m' "$venv"
[ -n "$node_version" ] && printf '  \033[0;90m│\033[0m  \033[0;32m%s\033[0m' "$node_version"

# Context (user@host)
printf '  \033[0;90m│\033[0m  \033[0;90m%s\033[0m' "$context"

# Add trailing spaces
printf '   '
