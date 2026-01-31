#!/usr/bin/env bash
#
# apply_partial_commits.sh
#
# Usage:
#   ./apply_partial_commits.sh /path/to/repoA /path/to/repoB paths.txt
#
# Description:
#   Selects all commits from repoA that modify files listed in paths.txt,
#   extracts only those file changes, and reapplies them to repoB,
#   preserving commit metadata and chronological order.
#
# Requirements:
#   - Both repos must exist locally and be valid Git repos.
#   - paths.txt: a plain text file with one path (relative to repoA root) per line.
#   - Run from any directory; temporary files are created under /tmp.

set -euo pipefail

REPO_A="${1:-}"
REPO_B="${2:-}"
PATHS_FILE="${3:-}"

if [[ -z "$REPO_A" || -z "$REPO_B" || -z "$PATHS_FILE" ]]; then
  echo "Usage: $0 /path/to/repoA /path/to/repoB paths.txt"
  exit 1
fi

[[ -d "$REPO_A/.git" ]] || { echo "Error: $REPO_A is not a Git repo."; exit 1; }
[[ -d "$REPO_B/.git" ]] || { echo "Error: $REPO_B is not a Git repo."; exit 1; }
[[ -f "$PATHS_FILE" ]]  || { echo "Error: $PATHS_FILE not found."; exit 1; }

TMP_DIR=$(mktemp -d)
COMMITS_FILE="$TMP_DIR/commits.txt"
PATCH_DIR="$TMP_DIR/patches"
mkdir -p "$PATCH_DIR"

echo "→ Finding commits in $REPO_A that modify paths from $PATHS_FILE..."
cd "$REPO_A"
git log --pretty=format:%H -- $(cat "$PATHS_FILE") > "$COMMITS_FILE"
echo "" >> "$COMMITS_FILE"

echo "→ Extracting per-commit filtered patches..."
while read -r commit; do
  git diff-tree -p "$commit^!" -- $(cat "$PATHS_FILE") > "$PATCH_DIR/$commit.patch"
done < "$COMMITS_FILE"

echo "→ Applying patches to $REPO_B..."
cd "$REPO_B"

# Apply in chronological order
tac "$COMMITS_FILE" | while read -r commit; do
  PATCH_FILE="$PATCH_DIR/$commit.patch"
  [[ -s "$PATCH_FILE" ]] || continue

  echo "  ↳ Applying commit $commit ..."
  
  if git apply --3way --whitespace=fix "$PATCH_FILE"; then
    git add -A
    GIT_AUTHOR_DATE="$(git -C "$REPO_A" show -s --format=%aD "$commit")" \
    GIT_COMMITTER_DATE="$(git -C "$REPO_A" show -s --format=%cD "$commit")" \
    git commit -F <(git -C "$REPO_A" show -s --format=%B "$commit") \
      --author="$(git -C "$REPO_A" show -s --format='%an <%ae>' "$commit")"
  else
    echo "  ⚠️  Skipping $commit — patch did not apply cleanly."
  fi
done

echo "✅ Done! All applicable commits from $REPO_A have been applied to $REPO_B."
echo "Temporary data stored in: $TMP_DIR"

