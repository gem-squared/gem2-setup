# @gem_squared/setup

Auto-installer for [GEM² MCP](https://gemsquared.ai) tools. Detects your AI tools and registers the TPMN Checker MCP server in each one.

## Supported Tools

| Tool | Config Format |
|------|--------------|
| Claude Code | `url` (streamable HTTP) |
| Claude Desktop | `command` + `args` (stdio via launcher + mcp-remote) |
| Cursor | `command` + `args` (stdio via launcher + mcp-remote) |
| Windsurf | `url` (streamable HTTP) |
| VS Code + Continue | `url` (streamable HTTP) |

## Install

### Option 1: npx (recommended)

```bash
npx @gem_squared/setup
```

### Option 2: curl

```bash
curl -sSL https://user-mgmt.gemsquared.ai/setup/install | bash
```

### Option 3: GitHub raw

```bash
bash <(curl -sSL https://raw.githubusercontent.com/gem-squared/gem2-setup/main/install.sh)
```

## Uninstall

```bash
npx @gem_squared/setup uninstall
```

Or:

```bash
curl -sSL https://user-mgmt.gemsquared.ai/setup/uninstall | bash
```

## What it does

1. Checks dependencies — installs `jq` if missing (via Homebrew, apt, or dnf)
2. Detects installed AI tools by checking config directories
3. Installs GEM² launcher — for tools that need Node.js (Claude Desktop, Cursor). The launcher finds Node >= 20 from nvm/fnm/Homebrew/system PATH on every start (self-healing).
4. Backs up each tool's config file
5. Registers the GEM² TPMN Checker MCP server in each config (preserves existing entries)
6. No secrets or API keys stored — OAuth handles authentication on first use

## After install

1. **Restart** your AI tool(s)
2. **First use** — your tool will open a browser window for GEM² OAuth login
3. **Enter your LLM API key** (Claude/OpenAI/Gemini) on the consent page — this key is encrypted in your session token and never stored on our servers
4. **Done** — GEM² TPMN tools are now available in your AI tool

## What gets registered

For Claude Code, Windsurf, and VS Code + Continue (streamable HTTP):

```json
{
  "mcpServers": {
    "gem2-tpmn": { "url": "https://mcp-tpmn-checker.gemsquared.ai/mcp" }
  }
}
```

For Claude Desktop and Cursor (stdio via launcher + mcp-remote):

```json
{
  "mcpServers": {
    "gem2-tpmn": {
      "command": "~/.gem2/launcher.sh",
      "args": ["https://mcp-tpmn-checker.gemsquared.ai/mcp"]
    }
  }
}
```

## Launcher (`~/.gem2/launcher.sh`)

For Claude Desktop and Cursor, the installer sets up a launcher at `~/.gem2/launcher.sh`. This launcher:
- Finds Node.js >= 20 (searches nvm, fnm, Homebrew, system PATH)
- Self-heals on every MCP start — if you update Node, it picks up the new version
- Runs `mcp-remote` to bridge stdio <-> HTTP for MCP communication

## Requirements

- **macOS** or **Linux** (Windows not yet supported)
- `jq` (auto-installed via Homebrew/apt/dnf if missing)
- Node.js >= 20 (only needed for Claude Desktop and Cursor; installer warns if not found)

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Intel + Apple Silicon) | Supported |
| Linux (Ubuntu, Debian, Fedora) | Supported |
| Windows | Not yet supported |

## Privacy & Security

- **No secrets stored** — the installer only writes MCP server URLs to config files
- **LLM API keys** are entered via OAuth consent in the browser, encrypted (AES-256-GCM), and embedded in your session token. They are never stored on GEM² servers.
- **Backups** — every config file is backed up before modification
- **Open source** — review the script before running

## Links

- **Setup guide:** https://gemsquared.ai/setup
- **Sign up / Log in:** https://user-mgmt.gemsquared.ai/login
- **Dashboard:** https://user-mgmt.gemsquared.ai/dashboard
- **Profile (manage keys):** https://user-mgmt.gemsquared.ai/profile

## License

MIT
