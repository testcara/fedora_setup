#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Git Repo Sync Script (Full Version)
#
# Reads a repo list file and keeps local clones in sync
# with upstream if provided.
#
# Usage:
#   ./sync-repos.sh repo-list.txt /path/to/local/dir
#
# Repo list format:
#   fork_url [upstream_url]
#   - One column: personal repo only (no upstream)
#   - Two columns: fork + upstream
# ============================================================

REPO_LIST_FILE=${1:-}
LOCAL_DIR=${2:-}

if [[ -z "$REPO_LIST_FILE" || -z "$LOCAL_DIR" ]]; then
    echo "Usage: $0 repo-list.txt /path/to/local/dir"
    exit 1
fi

# Ensure absolute path
LOCAL_DIR=$(realpath "$LOCAL_DIR")
mkdir -p "$LOCAL_DIR"
cd "$LOCAL_DIR" || exit 1

echo "Starting repo sync in $LOCAL_DIR ..."

while read -r line; do
    # Remove Windows \r and skip empty / comment lines
    line="${line//$'\r'/}"
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    fork_url=$(echo "$line" | awk '{print $1}')
    upstream_url=$(echo "$line" | awk '{print $2}')
    repo_name=$(basename "$fork_url" .git)

    echo "-------------------------------"
    echo "Processing $repo_name ..."

    # Clone repo if missing
    if [[ -d "$repo_name" ]]; then
        echo "Repository $repo_name already exists. Skipping clone."
    else
        echo "Cloning $repo_name from $fork_url ..."
        git clone "$fork_url" "$repo_name" || { echo "Failed to clone $fork_url"; continue; }
    fi

    cd "$repo_name" || { echo "Failed to cd into $repo_name"; continue; }

    # Handle upstream if provided
    if [[ -n "${upstream_url:-}" ]]; then
        if git remote | grep -q upstream; then
            echo "Upstream already exists for $repo_name."
        else
            git remote add upstream "$upstream_url"
            echo "Upstream added for $repo_name."
        fi

        # Detect default branch
        default_branch=$(git remote show upstream | awk '/HEAD branch/ {print $NF}')
        echo "Default branch detected: $default_branch"

        # Fetch upstream
        git fetch upstream "$default_branch" || { echo "Failed to fetch upstream for $repo_name"; cd "$LOCAL_DIR"; continue; }

        # Checkout local branch matching upstream
        if git show-ref --verify --quiet "refs/heads/$default_branch"; then
            git checkout "$default_branch"
        else
            git checkout -b "$default_branch" "origin/$default_branch" || git checkout "$default_branch"
        fi

        # Fast-forward merge from upstream
        echo "Fast-forwarding $default_branch from upstream..."
        git merge --ff-only "upstream/$default_branch" || echo "No updates to merge."

    else
        echo "No upstream provided for $repo_name. Skipping upstream sync."
    fi

    # Back to base dir
    cd "$LOCAL_DIR" || exit 1

done < "$REPO_LIST_FILE"

echo "✅ All repos processed."
