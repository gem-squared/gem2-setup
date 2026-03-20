#!/usr/bin/env node

/**
 * GEM² MCP Setup — Node.js entry point
 *
 * Delegates to install.sh (or uninstall.sh with --uninstall flag).
 * This wrapper exists so `npx @gemsquared/setup` works cross-platform.
 *
 * Usage:
 *   npx @gem_squared/setup            # install
 *   npx @gem_squared/setup uninstall  # uninstall
 */

const { execFileSync } = require("child_process");
const path = require("path");

const args = process.argv.slice(2);
const isUninstall = args.includes("uninstall") || args.includes("--uninstall");

const scriptDir = path.join(__dirname, "..");
const script = path.join(scriptDir, isUninstall ? "uninstall.sh" : "install.sh");

try {
  execFileSync("bash", [script], {
    stdio: "inherit",
    env: { ...process.env },
  });
} catch (err) {
  process.exit(err.status || 1);
}
