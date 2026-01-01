#!/bin/bash

input=$(cat)

# Load config from ~/.claude (persists across plugin updates)
config_file="$HOME/.claude/statusline-config.json"
if [ -f "$config_file" ]; then
  show_cwd=$(jq -r '.show_cwd // true' "$config_file")
  show_icons=$(jq -r '.show_icons // true' "$config_file")
  show_git=$(jq -r '.show_git // true' "$config_file")
  show_model=$(jq -r '.show_model // true' "$config_file")
  show_duration=$(jq -r '.show_duration // true' "$config_file")
  show_usage=$(jq -r '.show_usage // true' "$config_file")
  show_context=$(jq -r '.show_context // true' "$config_file")
else
  show_cwd=true
  show_icons=true
  show_git=true
  show_model=true
  show_duration=true
  show_usage=true
  show_context=true
fi

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "~"')

# Display path relative to home
home="$HOME"
if [[ "$cwd" == "$home" ]]; then
  dir="~"
elif [[ "$cwd" == "$home"/* ]]; then
  dir="~${cwd#$home}"
else
  dir="$cwd"
fi

# Icons (only if enabled)
if [ "$show_icons" = "true" ]; then
  os_icon=$(printf '\xef\xa3\xbf')
  git_icon=$(printf '\xee\x82\xa0')
  clock_icon=$(printf '\xef\x80\x97')
  usage_icon=$(printf '\xef\x82\xa0')
else
  os_icon=""
  git_icon=""
  clock_icon=""
  usage_icon=""
fi

# Git info
git_display=""
git_clean=""
if [ "$show_git" = "true" ]; then
  git_parts=()
  if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
    git_parts+=("$branch")

    if [[ -z $(git -C "$cwd" status --porcelain 2>/dev/null) ]]; then
      git_clean=true
    else
      git_clean=false
      modified_count=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      git_parts+=("~$modified_count")
    fi

    upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
      behind=$(git -C "$cwd" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
      ahead_behind=""
      [ "$ahead" -gt 0 ] && ahead_behind+="↑$ahead"
      [ "$behind" -gt 0 ] && ahead_behind+="↓$behind"
      [ -n "$ahead_behind" ] && git_parts+=("$ahead_behind")
    fi

    stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$stash_count" -gt 0 ] && [ "$show_icons" = "true" ]; then
      git_parts+=("$(printf '\xef\x81\x9c')$stash_count")
    elif [ "$stash_count" -gt 0 ]; then
      git_parts+=("stash:$stash_count")
    fi

    git_display="${git_parts[*]}"
  fi
fi

# Model name
model=""
if [ "$show_model" = "true" ]; then
  model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""' | sed 's/Claude //' | sed 's/ /-/g')
fi

# Context usage
context_pct=0
if [ "$show_context" = "true" ]; then
  cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
  cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
  cur_in=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
  cur_out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
  context_max=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
  context_used=$((cache_read + cache_create + cur_in + cur_out))
  if [ "$context_max" -gt 0 ] 2>/dev/null; then
    context_pct=$((context_used * 100 / context_max))
  fi
fi

# Session duration
duration_min=0
if [ "$show_duration" = "true" ]; then
  duration=$(echo "$input" | jq '.cost.total_duration_ms // 0')
  duration_min=$((duration / 60000))
fi

# API Usage
five_hr_int=0
seven_day_int=0
if [ "$show_usage" = "true" ]; then
  usage_cache="$HOME/.claude/usage-cache.json"
  cache_max_age=60

  if [ -f "$usage_cache" ]; then
    cache_age=$(($(date +%s) - $(stat -f %m "$usage_cache" 2>/dev/null || echo 0)))
  else
    cache_age=999999
  fi

  if [ "$cache_age" -gt "$cache_max_age" ]; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    if [ -n "$creds" ]; then
      token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      if [ -n "$token" ]; then
        curl -s -H "Authorization: Bearer $token" -H "anthropic-beta: oauth-2025-04-20" \
          "https://api.anthropic.com/api/oauth/usage" > "$usage_cache" 2>/dev/null
      fi
    fi
  fi

  if [ -f "$usage_cache" ]; then
    five_hr=$(jq -r '.five_hour.utilization // 0' "$usage_cache" 2>/dev/null)
    seven_day=$(jq -r '.seven_day.utilization // 0' "$usage_cache" 2>/dev/null)
    five_hr_int=${five_hr%.*}
    seven_day_int=${seven_day%.*}
    five_hr_int=${five_hr_int:-0}
    seven_day_int=${seven_day_int:-0}
  fi
fi

# Build output
first_segment=true

# CWD
if [ "$show_cwd" = "true" ]; then
  if [ "$show_icons" = "true" ]; then
    printf '\033[0;37m%s\033[0m  \033[0;36m%s\033[0m' "$os_icon" "$dir"
  else
    printf '\033[0;36m%s\033[0m' "$dir"
  fi
  first_segment=false
fi

# Git status
if [ "$show_git" = "true" ] && [ -n "$git_display" ]; then
  [ "$first_segment" = false ] && printf '  '
  if [ "$show_icons" = "true" ]; then
    printf '\033[0;35m%s %s\033[0m' "$git_icon" "$git_display"
  else
    printf '\033[0;35m%s\033[0m' "$git_display"
  fi
  if [ "$git_clean" = true ]; then
    printf ' \033[0;32m✓\033[0m'
  elif [ "$git_clean" = false ]; then
    printf ' \033[0;31m✗\033[0m'
  fi
  first_segment=false
fi

# Model
if [ "$show_model" = "true" ] && [ -n "$model" ]; then
  [ "$first_segment" = false ] && printf '  \033[0;90m│\033[0m  '
  printf '\033[0;34m%s\033[0m' "$model"
  first_segment=false
fi

# Duration
if [ "$show_duration" = "true" ] && [ "$duration_min" -gt 0 ]; then
  [ "$first_segment" = false ] && printf '  \033[0;90m│\033[0m  '
  if [ "$show_icons" = "true" ]; then
    printf '\033[0;90m%s %dm\033[0m' "$clock_icon" "$duration_min"
  else
    printf '\033[0;90m%dm\033[0m' "$duration_min"
  fi
  first_segment=false
fi

# Usage
if [ "$show_usage" = "true" ]; then
  [ "$first_segment" = false ] && printf '  \033[0;90m│\033[0m  '
  [ "$show_icons" = "true" ] && printf '%s ' "$usage_icon"

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
  first_segment=false
fi

# Context
if [ "$show_context" = "true" ]; then
  [ "$first_segment" = false ] && printf '  \033[0;90m│\033[0m  '
  if [ "$context_pct" -ge 80 ] 2>/dev/null; then
    printf '\033[0;31m\033[1mctx:%d%%\033[0m' "$context_pct"
  elif [ "$context_pct" -ge 50 ] 2>/dev/null; then
    printf '\033[0;33mctx:%d%%\033[0m' "$context_pct"
  else
    printf '\033[0;32mctx:%d%%\033[0m' "$context_pct"
  fi
fi

printf '   '
