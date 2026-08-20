#!/bin/zsh
#
# project_preview.sh - Preview helper for project picker
# Shows actual window state for running sessions, planned state for others
#

PROJECTS_FILE="$HOME/.tmux/projects.yaml"

# Extract project name from display line (remove indicator and window count)
# Input formats: "* project_name (N windows)" or "  project_name (N windows)"
project_name=$(echo "$1" | sed 's/^[* ] //' | sed 's/ (.*//')

if [[ -z "$project_name" ]]; then
    echo "No project selected"
    exit 0
fi

# Check if session is running
if tmux has-session -t "$project_name" 2>/dev/null; then
    # Show actual windows from running session
    echo "🟢 Running Session"
    echo ""
    
    # Get active window for this session
    active_window=$(tmux display-message -t "$project_name" -p "#{window_index}" 2>/dev/null)
    
    # List all windows with details
    tmux list-windows -t "$project_name" -F "#{window_index}|#{window_name}|#{window_panes}|#{window_active}" 2>/dev/null | while IFS='|' read -r index name panes is_active; do
        # Add indicator for active window
        if [[ "$is_active" == "1" ]]; then
            indicator="→"
        else
            indicator=" "
        fi
        
        # Show pane count if more than 1
        if [[ "$panes" -gt 1 ]]; then
            pane_info=" ($panes panes)"
        else
            pane_info=""
        fi
        
        echo "  $indicator $index: $name$pane_info"
    done
else
    # Show planned windows from YAML
    echo "📋 Planned Configuration"
    echo ""
    
    # Get window list from YAML with commands
    yq ".projects[] | select(.name == \"$project_name\") | .windows[] | .name + \"|\" + .command" "$PROJECTS_FILE" 2>/dev/null | \
    tr -d '"' | \
    awk -F'|' 'BEGIN {i=1} {
        cmd = $2
        if (cmd == "" || cmd == "null") {
            cmd_info = ""
        } else {
            cmd_info = " [" cmd "]"
        }
        printf "    %d: %s%s\n", i, $1, cmd_info
        i++
    }'
    
    # Check if no windows found
    if [[ $? -ne 0 ]] || [[ -z "$(yq ".projects[] | select(.name == \"$project_name\")" "$PROJECTS_FILE" 2>/dev/null)" ]]; then
        echo "  No configuration found"
    fi
fi
