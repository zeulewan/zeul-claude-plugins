---
name: custom-statusline
description: Set up custom Claude Code status line with Nerd Font icons, colors, git status, usage tracking, system info, and project context. NO EMOJIS - only Nerd Font icons and symbols. Use when configuring statusline, setting up status bar, or customizing Claude UI. Triggers with statusline, status bar, custom theme.
---

# Custom Status Line Setup

Sets up a comprehensive Claude Code status line with **Nerd Font icons only** (no emojis), ANSI colors, real-time usage tracking, git integration, and system monitoring.

## Quick Start: Interactive Configuration

Run the `/custom-statusline` command to interactively configure your status line. It will ask which elements you want:

- **Current directory** - Working directory path
- **Nerd Font icons** - All icons (os, git, clock, usage) - all or nothing
- **Git branch & status** - Branch, dirty/clean, ahead/behind, stash
- **Model name** - Current Claude model
- **Session duration** - Time elapsed in session
- **API usage (5h/7d)** - Claude API usage percentages
- **Context % till compact** - Context window usage

The command will generate a customized `~/.claude/statusline.sh` and config file.

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

### Context Display
- Session context window percentage
- Color-coded by usage level

### Cost & Duration
- Total duration in minutes

## Manual Setup

If you prefer manual setup instead of the command:

### Step 1: Copy Status Line Script

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

## Requirements

### Essential
- **Nerd Font installed** - For icons (JetBrains Mono, Hack, FiraCode, etc.)
- **jq installed** - For JSON parsing (`brew install jq`)
- **Git installed** - For git features
- **curl** - For API usage fetching

### Platform-Specific (macOS)
- **security** - Keychain access for API token

## Troubleshooting

**Icons not showing**: Install a Nerd Font and configure your terminal to use it

**No git branch**: Script shows nothing when not in a git repository

**Usage shows 0%**: API call failed. Check:
- Keychain has "Claude Code-credentials"
- Internet connection active
- API endpoint accessible

**Slow status line**: Increase `cache_max_age` in the script to reduce API calls

**Reconfigure**: Run `/custom-statusline` again to change your preferences
