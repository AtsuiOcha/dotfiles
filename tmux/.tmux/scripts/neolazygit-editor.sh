#!/usr/bin/env bash
# macOS-compatible editor script for tmux-neolazygit.
#
# Installed by copying over the plugin's own scripts/editor.sh (done by
# install.sh after TPM installs the plugin), because open-lazygit.sh hard-codes
# LAZYGIT_EDITOR to "$CURRENT_DIR/editor.sh" and ignores any user override.
#
# Differences from upstream (which is Linux-only):
#   * process tree walked with pgrep (BSD/macOS) instead of `pstree -paT`
#   * nvim socket discovered under ${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/nvim.$(whoami)}
#     because macOS nvim puts sockets under $TMPDIR/nvim.<user>/..., not
#     $XDG_RUNTIME_DIR (which is usually unset on macOS).
#
# Invoked as: editor.sh {{filename}} {{line}}

FILENAME=$1
LINE=${2:-0}

ORIGIN_PANE_OPTION="@neolazygit-origin-pane"

# Directory tree that nvim creates its --listen sockets under.
socket_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/nvim.$(whoami)}"

get_session_id() {
    if [ -n "$LAZYGIT_SESSION_ID" ]; then
        printf '%s\n' "$LAZYGIT_SESSION_ID"
        return
    fi

    tmux display-message -p "#{session_id}"
}

get_origin_pane() {
    local session_id
    session_id="$(get_session_id)"

    tmux show-options -t "$session_id" -qv "$ORIGIN_PANE_OPTION"
}

# Recursively collect a process and all of its descendant PIDs (macOS pgrep).
collect_descendants() {
    local parent=$1
    printf '%s\n' "$parent"
    local child
    for child in $(pgrep -P "$parent" 2>/dev/null); do
        collect_descendants "$child"
    done
}

# Check if there's a nvim instance in the origin pane and 'returns' its server
# socket, otherwise returns 0.
get_nvim_socket() {
    local origin_pane
    origin_pane="$(get_origin_pane)"

    if [ -z "$origin_pane" ]; then
        echo 0
        return
    fi

    local pid_of_origin
    pid_of_origin=$(tmux list-panes -sF "#{pane_pid}" \
                        -f "#{m:#{pane_id},${origin_pane}}")

    if [ -z "$pid_of_origin" ]; then
        echo 0
        return
    fi

    # All PIDs in the origin pane's process tree that are nvim.
    local all_pids nvim_pids
    all_pids="$(collect_descendants "$pid_of_origin")"
    nvim_pids="$(printf '%s\n' "$all_pids" | while read -r p; do
        [ -n "$p" ] || continue
        if ps -o comm= -p "$p" 2>/dev/null | grep -q '[n]vim'; then
            printf '%s\n' "$p"
        fi
    done)"

    # Find the first PID that has an nvim socket assigned.
    local nvim_pid nvim_socket
    for nvim_pid in $nvim_pids; do
        nvim_socket=$(find "$socket_dir" -type s -name "*nvim*" 2>/dev/null | grep "$nvim_pid" | head -n1)
        if [ -n "$nvim_socket" ]; then
            echo "$nvim_socket"
            return
        fi
    done

    echo 0
}

focus_nvim() {
    local origin_pane
    origin_pane="$(get_origin_pane)"

    if [ -z "$origin_pane" ]; then
        return
    fi

    local origin_window
    origin_window="$(tmux list-panes -sF "#I" -f "#{m:#D,${origin_pane}}")"

    if [ -z "$origin_window" ]; then
        return
    fi

    tmux selectw -t "$origin_window"
    tmux selectp -t "$origin_pane"
}

main() {
    local socket
    socket=$(get_nvim_socket)

    # If no socket, it means no nvim, so just open inside lazygit.
    if [[ $socket == 0 ]]; then
        nvim +"$LINE" "$FILENAME"
        exit 0
    fi

    focus_nvim

    # Open the file remotely at the expected line.
    nvim --server "$socket" --remote "$(realpath "$FILENAME")"
    nvim --server "$socket" --remote-send "<ESC>${LINE}gg"
}

main
