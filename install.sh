#!/usr/bin/env bash
set -euo pipefail

# GEM² MCP Auto-Install Script
# Registers GEM² MCP server URLs in detected AI tool configs.
# No secrets or API keys are stored — OAuth handles authentication.
#
# Usage:
#   curl -sSL https://gemsquared.ai/install | bash
#   npx @gemsquared/setup
#   bash <(curl -sSL https://raw.githubusercontent.com/gem-squared/gem2-setup/main/install.sh)

VERSION="1.0.1"
GEM2_TPMN_URL="https://mcp-tpmn-checker.gemsquared.ai/mcp"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

info()  { printf "${CYAN}%s${NC}\n" "$1"; }
ok()    { printf "${GREEN}  ✓ %s${NC}\n" "$1"; }
warn()  { printf "${YELLOW}  ⚠ %s${NC}\n" "$1"; }
fail()  { printf "${RED}  ✗ %s${NC}\n" "$1"; }
header(){ printf "\n${BOLD}%s${NC}\n" "$1"; }

# ─── Check jq dependency ───
check_jq() {
  if command -v jq &>/dev/null; then
    return 0
  fi

  warn "jq is required but not installed."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      info "Installing jq via Homebrew..."
      brew install jq
    else
      fail "Please install jq: brew install jq (or https://jqlang.github.io/jq/download/)"
      exit 1
    fi
  elif command -v apt-get &>/dev/null; then
    info "Installing jq via apt..."
    sudo apt-get install -y jq
  elif command -v dnf &>/dev/null; then
    info "Installing jq via dnf..."
    sudo dnf install -y jq
  else
    fail "Please install jq: https://jqlang.github.io/jq/download/"
    exit 1
  fi
}

# ─── Detect AI Tools ───
detect_tools() {
  TOOLS=()

  # Claude Code
  if [ -d "$HOME/.claude" ]; then
    TOOLS+=("claude-code")
  fi

  # Claude Desktop
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -d "$HOME/Library/Application Support/Claude" ]; then
      TOOLS+=("claude-desktop")
    fi
  else
    if [ -d "$HOME/.config/Claude" ]; then
      TOOLS+=("claude-desktop")
    fi
  fi

  # Cursor
  if [ -d "$HOME/.cursor" ]; then
    TOOLS+=("cursor")
  fi

  # Windsurf
  if [ -d "$HOME/.codeium/windsurf" ]; then
    TOOLS+=("windsurf")
  fi

  # VS Code + Continue
  if [ -d "$HOME/.continue" ]; then
    TOOLS+=("continue")
  fi
}

# ─── Get config file path for a tool ───
config_path() {
  local tool="$1"
  case "$tool" in
    claude-code)
      echo "$HOME/.claude/settings.json"
      ;;
    claude-desktop)
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
      else
        echo "$HOME/.config/Claude/claude_desktop_config.json"
      fi
      ;;
    cursor)
      echo "$HOME/.cursor/mcp.json"
      ;;
    windsurf)
      echo "$HOME/.codeium/windsurf/mcp_config.json"
      ;;
    continue)
      echo "$HOME/.continue/config.json"
      ;;
  esac
}

# ─── Human-readable tool name ───
tool_name() {
  local tool="$1"
  case "$tool" in
    claude-code)    echo "Claude Code" ;;
    claude-desktop) echo "Claude Desktop" ;;
    cursor)         echo "Cursor" ;;
    windsurf)       echo "Windsurf" ;;
    continue)       echo "VS Code + Continue" ;;
  esac
}

# ─── Register MCP servers in a config file ───
register_mcp() {
  local config_file="$1"
  local tool="$2"
  local dir
  dir=$(dirname "$config_file")

  # Create directory if needed
  mkdir -p "$dir"

  # Backup existing config
  if [ -f "$config_file" ]; then
    cp "$config_file" "${config_file}.gem2-backup.$(date +%s)"
  else
    echo '{}' > "$config_file"
  fi

  local tmp="${config_file}.gem2-tmp"

  # Claude Desktop and Cursor require command+args format (stdio via mcp-remote)
  # These apps don't load shell profiles, so we must use the full npx path.
  # Claude Code, Windsurf, and Continue support the url format (streamable HTTP)
  case "$tool" in
    claude-desktop|cursor)
      local npx_path
      npx_path=$(command -v npx 2>/dev/null || true)
      if [ -z "$npx_path" ]; then
        warn "npx not found — $(tool_name "$tool") requires Node.js for MCP bridge"
        warn "Install Node.js: https://nodejs.org/"
        return
      fi
      jq --arg tpmn "$GEM2_TPMN_URL" --arg npx "$npx_path" \
        '.mcpServers = ((.mcpServers // {}) * {
          "gem2-tpmn": {"command": $npx, "args": ["-y", "@anthropic/mcp-remote", $tpmn]}
        })' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
      ;;
    *)
      jq --arg tpmn "$GEM2_TPMN_URL" \
        '.mcpServers = ((.mcpServers // {}) * {
          "gem2-tpmn": {"url": $tpmn}
        })' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
      ;;
  esac

  ok "$(tool_name "$tool") — $(basename "$config_file")"
}

# ─── Main ───
main() {
  printf "\n${BOLD}${CYAN}GEM² MCP Setup${NC} ${CYAN}v${VERSION}${NC}\n"
  printf "${CYAN}─────────────────────────────${NC}\n"

  check_jq

  header "Detecting AI tools..."

  detect_tools

  # Show detection results
  for candidate in claude-code claude-desktop cursor windsurf continue; do
    local found=false
    for tool in "${TOOLS[@]}"; do
      if [ "$tool" = "$candidate" ]; then
        found=true
        break
      fi
    done
    if $found; then
      ok "$(tool_name "$candidate")"
    else
      printf "  ${YELLOW}[ ]${NC} $(tool_name "$candidate") ${YELLOW}(not found)${NC}\n"
    fi
  done

  if [ ${#TOOLS[@]} -eq 0 ]; then
    warn "No supported AI tools detected."
    info "Supported: Claude Code, Claude Desktop, Cursor, Windsurf, VS Code + Continue"
    info "Install one of these tools first, then re-run this script."
    exit 0
  fi

  header "Registering GEM² MCP servers..."

  for tool in "${TOOLS[@]}"; do
    local cfg
    cfg=$(config_path "$tool")
    register_mcp "$cfg" "$tool"
  done

  header "Done!"
  info ""
  info "Next steps:"
  info "  1. Restart your AI tool(s)"
  info "  2. First use will open browser for GEM² login"
  info "  3. Enter your LLM API keys in the consent form"
  info "  4. That's it — GEM² MCP tools are ready"
  info ""
  info "  Guide:      https://gemsquared.ai/setup"
  info "  Sign up:    https://gemsquared.ai/signup"
  info "  Dashboard:  https://gemsquared.ai/dashboard"
  info "  Uninstall:  curl -sSL https://gemsquared.ai/uninstall | bash"
  info ""
}

main "$@"
