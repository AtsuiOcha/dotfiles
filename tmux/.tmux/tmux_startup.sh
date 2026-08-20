#!/bin/zsh
#
# tmux_startup.sh - Lazy-loading tmux startup
# Only loads the admin session, then shows project picker
#

# Session: admin (in ~ with btop and nvim windows)
tmux new-session -d -s 00_admin -c ~ -n btop 'btop'
tmux new-window -t 00_admin:2 -n config -c ~/.config 'nvim'
tmux new-window -t 00_admin:3 -n zshell -c ~ 'nvim ~/.zshrc'
tmux new-window -t 00_admin:4 -n tmux -c ~/.tmux 'nvim ~/.tmux.conf'

# Select the first window
tmux select-window -t 00_admin:1

# Attach to admin session and immediately show project picker
# The picker runs in a popup so you can select a project right away
tmux attach-session -t 00_admin \; display-popup -E "$HOME/.tmux/project_picker.sh"
