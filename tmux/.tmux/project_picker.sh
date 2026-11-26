#!/bin/zsh
#
# project_picker.sh - fzf-based project selector for tmux
# Shows running sessions and configured projects
#

PROJECTS_FILE="$HOME/.tmux/projects.yaml"
LOAD_SCRIPT="$HOME/.tmux/load_project.sh"

# List running sessions first, then configured projects that are not running.
typeset -a entries
typeset -A running
while IFS=$'\t' read -r name count; do
    [[ -n "$name" ]] || continue
    running[$name]=1
    entries+=("* $name ($count windows)")
done < <(tmux list-sessions -F $'#{session_name}\t#{session_windows}' 2>/dev/null)

if [[ -f "$PROJECTS_FILE" ]]; then
    while IFS=$'\t' read -r name count; do
        [[ -n "$name" && -z "${running[$name]-}" ]] || continue
        entries+=("  $name ($count windows)")
    done < <(yq -r '.projects[] | [.name, (.windows | length)] | @tsv' "$PROJECTS_FILE")
fi

if (( ${#entries} == 0 )); then
    echo "No sessions or projects found"
    exit 1
fi

# Show fzf picker with preview
selected=$(printf '%s\n' "${entries[@]}" | fzf \
    --reverse \
    --header="Select a session or project (* = running)" \
    --preview="$HOME/.tmux/project_preview.sh {}" \
    --preview-window=right:40% \
    --ansi)

if [[ -z "$selected" ]]; then
    # User cancelled
    exit 0
fi

# Extract the session name (remove indicator and trailing window count).
project_name=$(printf '%s\n' "$selected" | sed -E 's/^[* ] //; s/ \([0-9]+ windows\)$//')

# Load/switch to the project
"$LOAD_SCRIPT" "$project_name"
