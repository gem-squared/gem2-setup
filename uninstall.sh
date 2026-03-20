#!/usr/bin/env bash
set -euo pipefail

# GEM² MCP Uninstall Script
# Removes GEM² MCP server entries from all detected AI tool configs.
# Does NOT remove any other MCP entries or user data.
#
# Usage:
#   npx @gem_squared/setup uninstall
#   curl -sSL https://user-mgmt.gemsquared.ai/setup/uninstall | bash

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

info()  { printf "${CYAN}%s${NC}\n" "$1"; }
ok()    { printf "${GREEN}  ✓ %s${NC}\n" "$1"; }
warn()  { printf "${YELLOW}  ⚠ %s${NC}\n" "$1"; }

# ─── Check jq ───
if ! command -v jq &>/dev/null; then
  printf "${RED}jq is required: https://jqlang.github.io/jq/download/${NC}\n"
  exit 1
fi

# ─── Config file paths ───
configs=()

# Claude Code
[ -f "$HOME/.claude/settings.json" ] && configs+=("$HOME/.claude/settings.json|Claude Code")

# Claude Desktop
if [[ "$OSTYPE" == "darwin"* ]]; then
  [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ] && \
    configs+=("$HOME/Library/Application Support/Claude/claude_desktop_config.json|Claude Desktop")
else
  [ -f "$HOME/.config/Claude/claude_desktop_config.json" ] && \
    configs+=("$HOME/.config/Claude/claude_desktop_config.json|Claude Desktop")
fi

# Cursor
[ -f "$HOME/.cursor/mcp.json" ] && configs+=("$HOME/.cursor/mcp.json|Cursor")

# Windsurf
[ -f "$HOME/.codeium/windsurf/mcp_config.json" ] && configs+=("$HOME/.codeium/windsurf/mcp_config.json|Windsurf")

# VS Code + Continue
[ -f "$HOME/.continue/config.json" ] && configs+=("$HOME/.continue/config.json|VS Code + Continue")

printf "\n${BOLD}${CYAN}GEM² MCP Uninstall${NC}\n"
printf "${CYAN}──────────────────────${NC}\n"

if [ ${#configs[@]} -eq 0 ]; then
  info "No GEM² MCP entries found in any AI tool configs."
  exit 0
fi

for entry in "${configs[@]}"; do
  IFS='|' read -r config_file tool_name <<< "$entry"

  # Check if gem2 entries exist
  if jq -e '.mcpServers["gem2-tpmn"] // .mcpServers["gem2-knowledge"]' "$config_file" &>/dev/null; then
    # Backup
    cp "$config_file" "${config_file}.gem2-backup.$(date +%s)"

    # Remove gem2 entries
    tmp="${config_file}.gem2-tmp"
    jq 'del(.mcpServers["gem2-tpmn"], .mcpServers["gem2-knowledge"])' \
      "$config_file" > "$tmp" && mv "$tmp" "$config_file"

    ok "$tool_name — removed GEM² MCP entries"
  else
    warn "$tool_name — no GEM² entries found (skipped)"
  fi
done

# Clean up launcher
if [ -d "$HOME/.gem2" ]; then
  rm -rf "$HOME/.gem2"
  ok "Removed ~/.gem2 launcher"
fi

printf "\n"
info "GEM² MCP entries removed. Restart your AI tools to apply."
info "Re-install anytime: npx @gem_squared/setup"
printf "\n"
