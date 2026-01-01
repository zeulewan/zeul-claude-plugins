---
name: custom-statusline
description: Set up custom Claude Code status line with Nerd Font icons, colors, git status, usage tracking, system info, and project context. NO EMOJIS - only Nerd Font icons and symbols. Use when configuring statusline, setting up status bar, or customizing Claude UI. Triggers with statusline, status bar, custom theme.
---

# Custom Status Line Setup

Sets up a comprehensive Claude Code status line with **Nerd Font icons only** (no emojis), ANSI colors, real-time usage tracking, git integration, and system monitoring.

**IMPORTANT**: This setup uses **ONLY Nerd Font icons** - no emoji characters. All icons are from Nerd Fonts using hex escape codes.

## Features

### Git Integration
- Clean/dirty status indicator
- Modified file count
- Ahead/behind tracking
- Stash count display
- Branch name with color coding

### Usage Tracking
- **5-hour and 7-day usage percentages** from Anthropic API
- Color-coded thresholds (green <50%, yellow 50-80%, red >80%)
- Cached for 60 seconds to avoid API spam

### Token Display
- Input/output tokens for current turn
- **Cache read tokens** shown separately (10x cheaper!)
- Session context window percentage

### Project Context
- Python version when in Python project
- Node version when in Node project
- Running Docker containers

### System Info
- Battery level with color coding
- WiFi network name

### Cost & Duration
- Session cost in USD
- Total duration in minutes

## Workflow

### Step 1: Copy Status Line Script

Copy the statusline.sh script from this plugin to your Claude config:

```bash
cp ${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### Step 2: Update Claude Settings

Update `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

### Step 3: Test Status Line

```bash
echo '{}' | ~/.claude/statusline.sh
```

Expected output should show colors and icons properly.

## Requirements

### Essential
- **Nerd Font installed** - For icons (JetBrains Mono, Hack, FiraCode, etc.)
- **jq installed** - For JSON parsing (`brew install jq`)
- **Git installed** - For git features
- **curl** - For API usage fetching

### Platform-Specific (macOS)
- **security** - Keychain access for API token
- **pmset** - Battery info
- **networksetup** - WiFi info

## Troubleshooting

**Icons not showing**: Install a Nerd Font and configure your terminal to use it

**No git branch**: Script shows "no-git" in gray when not in a git repository

**Usage shows "--"**: API call failed. Check:
- Keychain has "Claude Code-credentials"
- Internet connection active
- API endpoint accessible

**Slow status line**: Increase `cache_max_age` in the script to reduce API calls
