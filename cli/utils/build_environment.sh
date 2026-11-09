#!/bin/bash
#
# Install uv (if not already installed) and create the uv environment using the
# pyproject.toml, uv.lock, and .python-version files.
#
# Usage from the project's root directory:
#   ./cli/utils/build_environment.sh

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

# Install Codex
curl -fsSL https://chatgpt.com/codex/install.sh | sh

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
