#!/bin/bash
# Installs the tool/version managers themselves (once per machine).
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1 || [ -x "$2" ]; }

sudo apt-get update
sudo apt-get install -y curl git build-essential

have mise "$HOME/.local/bin/mise" || curl -fsSL https://mise.run | sh

have brew /home/linuxbrew/.linuxbrew/bin/brew ||
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

have oh-my-posh "$HOME/.local/bin/oh-my-posh" ||
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

[ -d "$HOME/.bun" ] || curl -fsSL https://bun.sh/install | bash

[ -x "$HOME/.opencode/bin/opencode" ] || curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
