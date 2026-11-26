#!/bin/zsh
#
# tmux_startup.sh - Lazy-loading tmux startup
# Only loads the admin session, then shows project picker
#

if [[ -z "$TMUX" && ! -t 0 ]]; then
    echo 'Run start tmux from an interactive terminal.' >&2
    exit 1
fi

if ! tmux has-session -t '=00_admin' 2>/dev/null; then
    # Build the admin workspace only once; a detached session is still running.
    tmux new-session -d -s 00_admin -c ~ -n btop 'btop'
    tmux new-window -t 00_admin:2 -n config -c ~/.config 'nvim'
    tmux new-window -t 00_admin:3 -n zshell -c ~ 'nvim ~/.zshrc'
    tmux new-window -t 00_admin:4 -n tmux -c ~/.tmux 'nvim ~/.tmux.conf'
    tmux new-window -t 00_admin:5 -n dotfiles -c ~/dotfiles
    tmux select-window -t 00_admin:1
fi

# Inside tmux, switch clients rather than nesting an attach in a pane.
if [[ -n "$TMUX" ]]; then
    tmux switch-client -t '=00_admin'
else
    tmux attach-session -t '=00_admin' \; display-popup -E "$HOME/.tmux/project_picker.sh"
fi
