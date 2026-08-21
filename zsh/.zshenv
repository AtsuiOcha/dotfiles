# Sourced for EVERY zsh invocation (interactive, non-interactive, scripts,
# GUI-launched, and tmux/nvim subshells). Env vars belong here so tools like
# neovim launched inside tmux always see them.

# Follow the XDG Base Directory spec so tools (e.g. lazygit) read their config
# from ~/.config/<tool> instead of platform-specific locations.
export XDG_CONFIG_HOME="$HOME/.config"

# Personal scripts (e.g. ai-commit-msg) symlinked here by install.sh.
export PATH="$HOME/.local/bin:$PATH"

# Load secrets (API keys, tokens, etc.)
[[ -f ~/.secrets ]] && source ~/.secrets
