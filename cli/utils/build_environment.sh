#!/bin/bash
#
# Install uv (if not already installed) and create the uv environment using the
# pyproject.toml, uv.lock, and .python-version files.
#
# Usage from the project's root directory:
#   ./cli/utils/build_environment.sh
# Requires Node.js 22.20 or later and Git for Claude Code extensions.

set -e

# Install uv if not already on PATH
if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found. Installing now..." >&2
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Check if uv is now on PATH
if ! command -v uv >/dev/null 2>&1; then
    echo "uv has been installed but is still not on PATH (try restarting your shell)" >&2
    exit 1
fi

# Create .venv/ with the Python version from .python-version and install
# the dependencies from pyproject.toml and uv.lock. uv sync also installs the
# local project in editable mode, using its current name from pyproject.toml.
uv sync

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"

# Install the i-have-adhd skill and make it always on
claude plugin marketplace add ayghri/i-have-adhd
claude plugin install i-have-adhd@i-have-adhd
mkdir -p "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
touch "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.i-have-adhd-always"

# Install the additional Claude Code plugins and skills.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/install_claude_extensions.sh"

# Install Codex without prompting to start it or remove another installation.
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
export PATH="$HOME/.local/bin:$PATH"

# Install the i-have-adhd skill for Codex and make it always on
codex plugin marketplace add ayghri/i-have-adhd --ref main
codex plugin add i-have-adhd@i-have-adhd
CODEX_AGENTS="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
mkdir -p "$(dirname "$CODEX_AGENTS")"
if ! grep -q "The reader has ADHD" "$CODEX_AGENTS" 2>/dev/null; then
    cat >> "$CODEX_AGENTS" <<'EOF'

## Output style

The reader has ADHD. Shape every response so it can be acted on:

1. Lead with the answer or next action: command, path, or snippet first.
2. Number multi-step work; one bounded action per step.
3. End with one next action doable in under two minutes.
4. Finish the current issue before raising a new one.
5. Restate progress each turn ("step 3 of 5 done").
6. Give time estimates in concrete units, never "a bit".
7. After a change, show what now works.
8. Errors: state location, cause, and fix. No drama.
9. Cap lists to 5 items.
10. No preamble, no recaps, no closers.

Exceptions: explain fully when asked to explain. Confirm before destructive actions. After three failed fixes, stop and name the doubtful assumption. If the request is ambiguous, ask one short question.
EOF
fi

# Install the additional Codex plugins and enable Task Observer by default.
bash "$SCRIPT_DIR/install_codex_extensions.sh"

# Create local settings without overwriting existing credentials.
if [ ! -e .env ]; then
    cat > .env <<'EOF'
WANDB_API_KEY=""
WANDB_CACHE_DIR=./wandb/cache
WANDB_CONFIG_DIR=./wandb/config
WANDB_DATA_DIR=./wandb/data
WANDB_ARTIFACTS_DIR=./wandb/artifacts
WANDB_DIR=./wandb
WANDB_ENTITY=""
WANDB_PROJECT=""

HF_TOKEN=""
EOF
fi

echo -e "\nCreated uv environment"
echo "Activate it with: source .venv/bin/activate"
