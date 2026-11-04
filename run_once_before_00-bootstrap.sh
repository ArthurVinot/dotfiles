#!/bin/bash
# Installs the tool/version managers themselves (once per machine).
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1 || [ -x "$2" ]; }

sudo apt-get update
sudo apt-get install -y curl git build-essential unzip

have mise "$HOME/.local/bin/mise" || curl -fsSL https://mise.run | sh

have brew /home/linuxbrew/.linuxbrew/bin/brew ||
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

have oh-my-posh "$HOME/.local/bin/oh-my-posh" ||
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

[ -d "$HOME/.bun" ] || curl -fsSL https://bun.sh/install | bash

# Install V2 on new machines and replace an existing V1 installation.
opencode_version=$("$HOME/.opencode/bin/opencode" --version 2>/dev/null || true)
if [[ "$opencode_version" != 2.* ]]; then
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
fi
