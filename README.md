# zeul-claude-plugins

Personal Claude Code plugin marketplace with utilities, development tools, and customization plugins.

## Installation

Add this marketplace to Claude Code:

```bash
claude plugin install apod@zeul-claude-plugins --marketplace github:zeul/zeul-claude-plugins
```

Or add the marketplace first, then install plugins:

```bash
# Add marketplace
claude plugin marketplace add zeul-claude-plugins github:zeul/zeul-claude-plugins

# Install individual plugins
claude plugin install apod@zeul-claude-plugins
claude plugin install custom-statusline@zeul-claude-plugins
claude plugin install generate-skill@zeul-claude-plugins
```

## Available Plugins

### apod
Download NASA's Astronomy Picture of the Day with metadata. Saves high-resolution images and descriptions to `~/Desktop/APOD/`.

**Usage:** "Download today's APOD" or "Get the astronomy picture of the day"

**Requirements:** `pip install requests beautifulsoup4`

### custom-statusline
Comprehensive Claude Code status line with Nerd Font icons, git integration, API usage tracking, and system monitoring. Features:
- Git branch, dirty/clean status, ahead/behind tracking
- 5-hour and 7-day API usage percentages (color-coded)
- Context window usage
- Python/Node/Docker environment detection
- Battery and WiFi info (macOS)

**Requirements:** Nerd Font, jq, curl

### generate-skill
Create new Claude Code skills with proper structure and best practices. Guides you through:
- Understanding purpose and use cases
- Recommending structure (workflow, task, reference, capabilities)
- Generating SKILL.md with frontmatter
- Organizing resources (scripts, references, assets)

### chrome-devtools
Chrome DevTools MCP guide for browser automation with parallel agent support. Documents:
- Multi-server setup for parallel agents
- Server selection and cleanup
- Common troubleshooting

### zensical-debug
Debug and visually verify zensical/Material for MkDocs sites with Chrome DevTools MCP. Includes:
- Chrome debugging port management
- Visual verification commands
- CSS refresh procedures

### zensical-development
Best practices for developing zensical/Material for MkDocs static sites. Covers:
- Virtual environment setup
- Project structure
- Responsive images and CSS
- YouTube embedding
- Visual verification workflow

## Plugin Structure

```
zeul-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── apod/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/apod/
│   │       ├── SKILL.md
│   │       └── download_apod.py
│   ├── custom-statusline/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/custom-statusline/SKILL.md
│   │   └── scripts/statusline.sh
│   ├── generate-skill/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/generate-skill/
│   │       ├── SKILL.md
│   │       ├── references/
│   │       └── examples/
│   ├── chrome-devtools/
│   ├── zensical-debug/
│   └── zensical-development/
└── README.md
```

## License

MIT
