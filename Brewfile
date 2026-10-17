# Check:   brew bundle check --file="$HOME/.Brewfile" --no-upgrade
# Install: brew bundle --file="$HOME/.Brewfile" --no-upgrade

# Shells and environment
brew "starship"

# Navigation, search and terminal interfaces
brew "bat"
brew "btop"
brew "eza"
brew "fd"
brew "fzf"
brew "jq"
brew "ripgrep"
brew "tealdeer"
brew "tmux"
brew "yq"
brew "zoxide"

# Version control
brew "gh"
brew "git"
brew "git-delta"
brew "lazygit"

# Build tooling; use native OS compilers, Make and debuggers.
brew "cmake"
brew "llvm" # clangd; keep native compiler/debugger defaults

# Language tools
# Brew owns pnpm; pnpm owns Node LTS, npm/npx and Pi. See the setup notes.
# Subsequent setup (not executed by Brew Bundle):
#   pnpm runtime set node lts -g
#   pnpm add -g npm @earendil-works/pi-coding-agent
# uv continues managing project Pythons.
brew "pnpm"
brew "uv"
# Python editor tools are installed with uv; see scripts/setup-editor-tools.

# Brew owns rustup itself; rustup owns toolchains/components. See the setup notes.
brew "rustup"

# Editor and parser tooling; language servers use their ecosystem managers.
brew "neovim"
brew "tree-sitter-cli"
brew "tombi"

# Coding agents; CLI-only casks belong in the baseline too.
brew "anomalyco/tap/opencode-v2", trusted: true
# Pi is installed through pnpm above. Hermes retains its upstream installer
# and updater: both Homebrew formulae would pull in Homebrew Node.
brew "herdr"
cask "claude-code"
cask "codex"
cask "copilot-cli", greedy: true # update through Brew even though upstream supports auto-updates
cask "grok-build"

# Cloud, networking and file utilities
brew "awscli"

# Media, document and font processing CLIs
brew "ffmpeg"

# Diagnostics
brew "valgrind" if OS.linux?
