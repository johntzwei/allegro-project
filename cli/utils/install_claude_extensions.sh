#!/bin/bash
# Install the template's Claude Code extensions for the current user.
# Run separately to install extensions without rebuilding the environment.

set -euo pipefail

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
SKILLS_CLI_VERSION="1.8.1"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for required_command in node npm npx git "$CLAUDE_BIN"; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Required command not found: $required_command" >&2
        echo "Install Node.js, Git, and Claude Code, then retry." >&2
        exit 1
    fi
done

# The skills CLI requires Node.js 22.20 or later.
node -e '
const [major, minor] = process.versions.node.split(".").map(Number);
if (major < 22 || (major === 22 && minor < 20)) {
    console.error("Install Node.js 22.20 or later, then retry.");
    process.exit(1);
}
'

# Claude-Mem's plugin packages require Bun before plugin installation.
if ! command -v bun >/dev/null 2>&1; then
    # A user-owned prefix avoids administrator access on shared machines.
    npm install --global --prefix "$HOME/.local" bun
    export PATH="$HOME/.local/bin:$HOME/.local:$PATH"
fi
if ! command -v bun >/dev/null 2>&1; then
    echo "Bun is not on PATH. Restart the shell and retry." >&2
    exit 1
fi

ensure_marketplace() {
    local source="$1"
    local name="$2"
    local marketplaces
    marketplaces=$("$CLAUDE_BIN" plugin marketplace list --json)
    if ! printf '%s' "$marketplaces" | node -e '
const fs = require("node:fs");
const entries = JSON.parse(fs.readFileSync(0, "utf8"));
process.exit(entries.some(entry => entry.name === process.argv[1]) ? 0 : 1);
' "$name"; then
        "$CLAUDE_BIN" plugin marketplace add "$source"
    fi
}

# These plugins include their own skills and hooks.
ensure_marketplace anthropics/claude-plugins-official claude-plugins-official
"$CLAUDE_BIN" plugin install superpowers@claude-plugins-official --scope user
ensure_marketplace thedotmack/claude-mem thedotmack
"$CLAUDE_BIN" plugin install claude-mem@thedotmack --scope user
# Complete dependency setup if an earlier installation lacked Bun.
"$CLAUDE_BIN" plugin update claude-mem@thedotmack

# Copies work on Windows without requiring symlink privileges.
npx --yes "skills@$SKILLS_CLI_VERSION" add vercel-labs/skills \
    --skill find-skills --global --agent claude-code --yes --copy
npx --yes "skills@$SKILLS_CLI_VERSION" add \
    rebelytics/one-skill-to-rule-them-all \
    --skill task-observer --global --agent claude-code --yes --copy
PLOTS_SOURCE="https://github.com/Microck/ordinary-claude-skills"
PLOTS_SOURCE+="/tree/main/skills_all/data-viz-plots"
npx --yes "skills@$SKILLS_CLI_VERSION" add "$PLOTS_SOURCE" \
    --skill data-viz-plots --global --agent claude-code --yes --copy

echo "Installed Claude Code plugins and skills for the current user."
node "$SCRIPT_DIR/configure_task_observer.mjs" --agent claude-code
echo "Restart Claude Code to load the new extensions."
