#!/bin/bash

# Colors for nice printing
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # No Color

# 1. Input Directory
TARGET_DIR="${1:-.}" # Default to current directory if no argument provided

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory $TARGET_DIR does not exist.${NC}"
    exit 1
fi

echo -e "${BLUE}Inspecting repositories in: $TARGET_DIR${NC}\n"

# Formatting string for the table
# %-30s means left-align 30 chars wide
FORMAT="%-35s | %-20s | %-20s\n"

printf "$FORMAT" "REPOSITORY" "LOCAL STATUS" "REMOTE STATUS"
echo "---------------------------------------------------------------------------------"

# Array to store repos that need pulling
needs_pull_list=()

# 2. Iterate through direct children
for repo in "$TARGET_DIR"/*/; do
    # Check if it is a directory and has a .git folder
    if [ -d "$repo" ] && [ -d "$repo/.git" ]; then
        repo_name=$(basename "$repo")
        
        # Move into directory (in a subshell to not affect main script)
        (
            cd "$repo" || exit

            # --- CHECK LOCAL CHANGES ---
            # Check for uncommitted changes
            if [[ -n $(git status --porcelain) ]]; then
                local_msg="${RED}Dirty (Unstaged)${NC}"
            else
                local_msg="${GREEN}Clean${NC}"
            fi

            # --- CHECK REMOTE CHANGES ---
            # We must fetch to know if we are behind, but we suppress output
            git fetch -q 2>/dev/null

            # Check if upstream is configured
            UPSTREAM=${1:-'@{u}'}
            LOCAL=$(git rev-parse @ 2>/dev/null)
            REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)
            BASE=$(git merge-base @ "$UPSTREAM" 2>/dev/null)

            if [ -z "$REMOTE" ]; then
                remote_msg="${YELLOW}No Upstream${NC}"
            elif [ "$LOCAL" = "$REMOTE" ]; then
                remote_msg="${GREEN}Up to date${NC}"
            elif [ "$LOCAL" = "$BASE" ]; then
                remote_msg="${YELLOW}▼ Behind (Needs Pull)${NC}"
            elif [ "$REMOTE" = "$BASE" ]; then
                remote_msg="${BLUE}▲ Ahead (Push)${NC}"
            else
                remote_msg="${RED}Diverged${NC}"
            fi

            printf "$FORMAT" "$repo_name" "$local_msg" "$remote_msg"
        )
    fi
done

echo ""
echo "---------------------------------------------------------------------------------"
