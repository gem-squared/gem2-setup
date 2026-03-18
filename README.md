# @gem_squared/setup

Auto-installer for [GEM² MCP](https://gemsquared.ai) tools. Detects your AI tools and registers the TPMN Checker MCP server in each one.

## Supported Tools

| Tool | Config Format |
|------|--------------|
| Claude Code | `url` (streamable HTTP) |
| Claude Desktop | `command` + `args` (stdio via mcp-remote) |
| Cursor | `command` + `args` (stdio via mcp-remote) |
| Windsurf | `url` (streamable HTTP) |
| VS Code + Continue | `url` (streamable HTTP) |

## Install

### Option 1: npx (recommended)

```bash
npx @gem_squared/setup
```

### Option 2: curl

```bash
curl -sSL https://gemsquared.ai/install | bash
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
curl -sSL https://gemsquared.ai/uninstall | bash
```

## What it does

1. Detects installed AI tools by checking config directories
2. Backs up each tool's config file
3. Merges the GEM² TPMN Checker MCP server URL into each config (preserves existing entries)
4. No secrets or API keys stored — OAuth handles authentication on first use

## Requirements

- **macOS** or **Linux** (Windows coming soon)
- `jq` (auto-installed via Homebrew/apt/dnf if missing)
- `npx` / Node.js (required for Claude Desktop and Cursor MCP bridge)

## What gets registered

```json
{
  "mcpServers": {
    "gem2-tpmn": { "url": "https://mcp-tpmn-checker.gemsquared.ai/mcp" }
  }
}
```

Claude Desktop and Cursor use the `command` + `args` format with `mcp-remote` as a bridge:

```json
{
  "mcpServers": {
    "gem2-tpmn": {
      "command": "/path/to/npx",
      "args": ["-y", "mcp-remote", "https://mcp-tpmn-checker.gemsquared.ai/mcp"]
    }
  }
}
```

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Intel + Apple Silicon) | Supported |
| Linux (Ubuntu, Debian, Fedora) | Supported |
| Windows | Coming soon |

## Links

- **Setup Guide**: https://gemsquared.ai/setup
- **Sign up**: https://gemsquared.ai/signup
- **Dashboard**: https://gemsquared.ai/dashboard
- **TPMN Specification**: https://gemsquared.ai/tpmn

## License

MIT
