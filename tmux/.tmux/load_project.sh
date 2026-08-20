#!/bin/zsh
#
# load_project.sh - Load a tmux project session from projects.yaml
# Usage: load_project.sh <project_name>
#

set -e

PROJECTS_FILE="$HOME/.tmux/projects.yaml"
PROJECT_NAME="$1"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Usage: load_project.sh <project_name>"
    exit 1
fi

if [[ ! -f "$PROJECTS_FILE" ]]; then
    echo "Error: Projects file not found: $PROJECTS_FILE"
    exit 1
fi

# Check if session already exists
if tmux has-session -t "$PROJECT_NAME" 2>/dev/null; then
    # Session exists, just switch to it
    tmux switch-client -t "$PROJECT_NAME"
    exit 0
fi

# Get project data from YAML
project_data=$(yq ".projects[] | select(.name == \"$PROJECT_NAME\")" "$PROJECTS_FILE")

if [[ -z "$project_data" ]]; then
    echo "Error: Project '$PROJECT_NAME' not found in $PROJECTS_FILE"
    exit 1
fi

# Extract base path (expand ~ to $HOME)
base_path=$(echo "$project_data" | yq '.path' | sed "s|^~|$HOME|")

# Get number of windows
window_count=$(echo "$project_data" | yq '.windows | length')

if [[ "$window_count" -eq 0 ]]; then
    echo "Error: No windows defined for project '$PROJECT_NAME'"
    exit 1
fi

# Create session with first window
first_window_name=$(echo "$project_data" | yq '.windows[0].name')
first_window_subpath=$(echo "$project_data" | yq '.windows[0].subpath')
first_window_command=$(echo "$project_data" | yq '.windows[0].command')

# Build full path for first window
if [[ "$first_window_subpath" == "." ]]; then
    first_window_path="$base_path"
else
    first_window_path="$base_path/$first_window_subpath"
fi

# Create the session with the first window
if [[ -n "$first_window_command" && "$first_window_command" != "null" ]]; then
    tmux new-session -d -s "$PROJECT_NAME" -c "$first_window_path" -n "$first_window_name" "$first_window_command"
else
    tmux new-session -d -s "$PROJECT_NAME" -c "$first_window_path" -n "$first_window_name"
fi

# Create remaining windows
for ((i = 1; i < window_count; i++)); do
    window_name=$(echo "$project_data" | yq ".windows[$i].name")
    window_subpath=$(echo "$project_data" | yq ".windows[$i].subpath")
    window_command=$(echo "$project_data" | yq ".windows[$i].command")

    # Build full path
    if [[ "$window_subpath" == "." ]]; then
        window_path="$base_path"
    else
        window_path="$base_path/$window_subpath"
    fi

    # Create window (window index is i+1 since tmux starts at 1)
    window_index=$((i + 1))
    if [[ -n "$window_command" && "$window_command" != "null" ]]; then
        tmux new-window -t "$PROJECT_NAME:$window_index" -n "$window_name" -c "$window_path" "$window_command"
    else
        tmux new-window -t "$PROJECT_NAME:$window_index" -n "$window_name" -c "$window_path"
    fi
done

# Select the first window
tmux select-window -t "$PROJECT_NAME:1"

# Switch to the new session
tmux switch-client -t "$PROJECT_NAME"
