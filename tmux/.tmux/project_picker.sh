#!/bin/zsh
#
# project_picker.sh - fzf-based project selector for tmux
# Shows available projects and loads the selected one
#

PROJECTS_FILE="$HOME/.tmux/projects.yaml"
LOAD_SCRIPT="$HOME/.tmux/load_project.sh"

if [[ ! -f "$PROJECTS_FILE" ]]; then
    echo "Error: Projects file not found: $PROJECTS_FILE"
    exit 1
fi

# Get list of project names with window count for display
# Format: "project_name (N windows)"
project_list=$(yq '.projects[] | .name + " (" + (.windows | length | tostring) + " windows)"' "$PROJECTS_FILE" | tr -d '"')

if [[ -z "$project_list" ]]; then
    echo "No projects found in $PROJECTS_FILE"
    exit 1
fi

# Check which sessions are already running
running_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || echo "")

# Add indicators for running sessions
display_list=""
while IFS= read -r line; do
    project_name=$(echo "$line" | sed 's/ (.*//')
    if echo "$running_sessions" | grep -q "^${project_name}$"; then
        display_list+="* $line\n"
    else
        display_list+="  $line\n"
    fi
done <<< "$project_list"

# Show fzf picker with preview
selected=$(echo -e "$display_list" | fzf \
    --reverse \
    --header="Select a project (* = running)" \
    --preview="$HOME/.tmux/project_preview.sh {}" \
    --preview-window=right:40% \
    --ansi)

if [[ -z "$selected" ]]; then
    # User cancelled
    exit 0
fi

# Extract project name (remove the leading indicator and window count)
project_name=$(echo "$selected" | sed 's/^[* ] //' | sed 's/ (.*//')

# Load/switch to the project
"$LOAD_SCRIPT" "$project_name"
