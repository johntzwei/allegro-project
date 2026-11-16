#!/bin/bash
# Install the template's Codex extensions for the current user.
set -euo pipefail

if [ -z "${CODEX_BIN:-}" ]; then
    # Desktop bundles can also contain an extensionless non-Windows binary.
    if command -v codex.exe >/dev/null 2>&1; then
        CODEX_BIN="codex.exe"
    else
        CODEX_BIN="codex"
    fi
fi
SKILLS_CLI_VERSION="1.8.1"
CLAUDE_MEM_VERSION="15.18.5"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for required_command in node npm npx git "$CODEX_BIN"; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "Required command not found: $required_command" >&2
        exit 1
    fi
done
node -e '
const [major, minor] = process.versions.node.split(".").map(Number);
if (major < 22 || (major === 22 && minor < 20)) {
    console.error("Install Node.js 22.20 or later, then retry.");
    process.exit(1);
}
'
if ! command -v bun >/dev/null 2>&1; then
    npm install --global --prefix "$HOME/.local" bun
    export PATH="$HOME/.local/bin:$HOME/.local:$PATH"
fi
# The Claude-Mem installer needs bun.exe, not npm's Windows command shim.
if command -v cygpath >/dev/null 2>&1; then
    BUN_NATIVE_DIR="$(cygpath -u "$(npm root --global)/bun/bin")"
    if [ -f "$BUN_NATIVE_DIR/bun.exe" ]; then
        export PATH="$BUN_NATIVE_DIR:$PATH"
    elif [ -f "$HOME/.local/node_modules/bun/bin/bun.exe" ]; then
        export PATH="$HOME/.local/node_modules/bun/bin:$PATH"
    fi
fi

marketplaces=$("$CODEX_BIN" plugin marketplace list --json)
if ! printf '%s' "$marketplaces" | node -e '
const fs = require("node:fs");
const data = JSON.parse(fs.readFileSync(0, "utf8"));
process.exit(data.marketplaces.some(p => p.name === "openai-curated") ? 0 : 1);
'; then
    "$CODEX_BIN" plugin marketplace add openai/plugins --ref main
fi
"$CODEX_BIN" plugin add superpowers@openai-curated

# This installs Codex's native memory plugin and capture hooks together.
# Keep the existing provider and leave the worker stopped during setup.
npx --yes "claude-mem@$CLAUDE_MEM_VERSION" install \
    --ide codex-cli --no-auto-start

npx --yes "skills@$SKILLS_CLI_VERSION" add vercel-labs/skills \
    --skill find-skills --global --agent codex --yes --copy
npx --yes "skills@$SKILLS_CLI_VERSION" add \
    rebelytics/one-skill-to-rule-them-all \
    --skill task-observer --global --agent codex --yes --copy
PLOTS_SOURCE="https://github.com/Microck/ordinary-claude-skills"
PLOTS_SOURCE+="/tree/main/skills_all/data-viz-plots"
npx --yes "skills@$SKILLS_CLI_VERSION" add "$PLOTS_SOURCE" \
    --skill data-viz-plots --global --agent codex --yes --copy

node "$SCRIPT_DIR/configure_task_observer.mjs" --agent codex
echo "Installed Codex extensions. Start a new chat and review /hooks."
