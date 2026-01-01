---
description: Configure your Claude Code status line interactively
---

# Custom Statusline Configuration

Configure the user's Claude Code status line by asking what elements they want displayed.

## Step 1: Ask User Preferences

Use AskUserQuestion with these exact options (split into 2 questions due to 4-option limit):

**Question 1 - Core elements:**
```
Question: "Which core elements do you want in your status line?"
Header: "Core"
multiSelect: true
Options:
1. Label: "Current directory", Description: "Show working directory path"
2. Label: "Nerd Font icons", Description: "Show all icons (requires Nerd Font installed)"
3. Label: "Git branch & status", Description: "Show branch, dirty/clean, ahead/behind"
4. Label: "Model name", Description: "Show current Claude model"
```

**Question 2 - Tracking elements:**
```
Question: "Which tracking elements do you want?"
Header: "Tracking"
multiSelect: true
Options:
1. Label: "Session duration", Description: "Show time elapsed in session"
2. Label: "API usage (5h/7d)", Description: "Show Claude API usage percentages"
3. Label: "Context % till compact", Description: "Show context window usage"
```

## Step 2: Write Config File

Based on user selections, write `~/.claude/statusline-config.json`:

```json
{
  "show_cwd": true,
  "show_icons": true,
  "show_git": true,
  "show_model": true,
  "show_duration": true,
  "show_usage": true,
  "show_context": true
}
```

Set each value to `true` or `false` based on whether the user selected that option.

## Step 3: Update Settings to Use Plugin Script

The statusline.sh script is included in the plugin. Update `~/.claude/settings.json` to point to it using a shell wrapper that finds the plugin's script:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c \"$(find ~/.claude/plugins/cache/zeul-claude-plugins/custom-statusline -name statusline.sh 2>/dev/null | head -1)\""
  }
}
```

This wrapper dynamically locates the script in the plugin cache, so it survives plugin version updates.

## Step 4: Notify User

Tell the user:
- Configuration saved to `~/.claude/statusline-config.json`
- Script is provided by the plugin (no copy needed)
- Settings updated to use the plugin's script
- Restart Claude Code to see changes
- Run `/custom-statusline` again to reconfigure
