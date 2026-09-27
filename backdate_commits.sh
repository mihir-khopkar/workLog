#!/bin/bash
set -euo pipefail

# Navigate to the repository
cd "$(dirname "$0")"

# Use your own repo URL instead of a hardcoded remote owned by someone else.
# Example:
#   ./backdate_commits.sh https://github.com/mihir-khopkar/workLog.git
REMOTE_URL="${1:-${GITHUB_REMOTE_URL:-}}"

if [ -z "$REMOTE_URL" ]; then
  echo "Usage: $0 <remote-url>"
  echo "Example: $0 https://github.com/mihir-khopkar/workLog.git"
  echo "Or set GITHUB_REMOTE_URL before running script."
  exit 1
fi

# Ensure the repository is initialized
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
fi

# Add or update the remote repository using the provided URL
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

# Commit message file
COMMIT_FILE="1000_commit_messages.txt"

# Check that the commit message file exists
if [ ! -f "$COMMIT_FILE" ]; then
  echo "Error: $COMMIT_FILE not found."
  exit 1
fi

# Load commit messages into an array
mapfile -t commit_messages < "$COMMIT_FILE"

# Remove numbering such as "0001. " from each message
for i in "${!commit_messages[@]}"; do
  commit_messages[$i]="${commit_messages[$i]#*. }"
done

# Make sure there are messages
if [ ${#commit_messages[@]} -eq 0 ]; then
  echo "Error: No commit messages found."
  exit 1
fi

echo "Loaded ${#commit_messages[@]} commit messages."

# Loop through the last 621 days
for i in {0..620}
do
  # Generate a random number of commits for the day (2 to 9)
  num_commits=$((RANDOM % 8 + 2))

  for ((j=1; j<=num_commits; j++))
  do
    # Generate a random time for that day
    commit_date=$(date -d "$i days ago $((RANDOM % 24)) hours $((RANDOM % 60)) minutes" \
      +"%Y-%m-%dT%H:%M:%S")

    # Pick a random commit message
    commit_message="${commit_messages[$((RANDOM % ${#commit_messages[@]}))]}"

    echo "[$commit_date] $commit_message"

    # Stage all existing files
    git add -A

    # Commit with the backdated date and random message
    GIT_COMMITTER_DATE="$commit_date" \
    GIT_AUTHOR_DATE="$commit_date" \
    git commit --allow-empty -m "$commit_message"
  done
done

# Set main branch
git branch -M main

# Push commits to the remote repository
git push -u origin main --force