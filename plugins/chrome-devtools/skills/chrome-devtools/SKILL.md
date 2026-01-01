---
name: chrome-devtools
description: Chrome DevTools MCP for browser automation. Five servers configured for parallel agents. Auto-select available server, cleanup when done.
---

# Chrome DevTools MCP

Five MCP servers configured: `chrome-devtools`, `chrome-devtools-2`, `chrome-devtools-3`, `chrome-devtools-4`, `chrome-devtools-5`

## Quick Start
1. `list_pages` - Initialize browser, see open pages
2. `new_page(url)` - Open URL (auto-selects new page)
3. `take_screenshot(filePath)` - Capture to file
4. `close_page(pageIdx)` - Close page by index

## Multi-Agent: Auto-Select Available Server

**Check availability** - Server is available if `list_pages` returns only `about:blank`:

```
Check servers in order until one is available:
1. mcp__chrome-devtools__list_pages
2. mcp__chrome-devtools-2__list_pages
3. mcp__chrome-devtools-3__list_pages
4. mcp__chrome-devtools-4__list_pages
5. mcp__chrome-devtools-5__list_pages

→ Only "about:blank"? Use that server's tools
→ Has other pages? Check next server...
→ All busy? Cleanup one (close_page for index > 0), then use it
```

**Why multiple servers?** Parallel Task agents sharing ONE server race-condition on "selected page". Each server = own browser = no conflicts.

## Cleanup After Use (No Auto-Timeout)

Chrome-devtools-mcp has NO idle timeout. Manually free servers:

```
# After completing work:
1. list_pages → note indices
2. close_page(pageIdx=N) for each page except about:blank (index 0)
```

## Troubleshooting

**"Browser already running" / stale locks:**
```bash
rm -f ~/.cache/chrome-devtools-mcp/chrome-profile/Singleton*
```

**Race condition with parallel agents:**
- Don't run parallel agents on SAME server
- Use chrome-devtools for Agent 1, chrome-devtools-2 for Agent 2

**Page not loading:**
- Check URL is valid
- Try `wait_for(text)` after navigation

## Server Configuration

Both servers use `--headless --isolated`:
- `--headless` = No visible browser window
- `--isolated` = Temp profile, auto-cleaned on close

Add more servers if needed:
```bash
claude mcp add chrome-devtools-3 --scope user -- npx chrome-devtools-mcp@latest --headless --isolated
```
