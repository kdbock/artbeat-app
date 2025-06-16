#!/bin/zsh

echo "Removing large test cache files from git history..."

# List of patterns to remove
patterns=(
  "packages/*/build/test_cache/build/cache.dill.track.dill"
  "packages/*/build/**/*.dill"
  "**/test_cache/**"
)

for pattern in "${patterns[@]}"; do
  echo "Removing $pattern from git history..."
  git filter-branch --force --index-filter \
    "git rm -rf --cached --ignore-unmatch $pattern" \
    --prune-empty --tag-name-filter cat -- --all
done

echo "Cleaning up..."
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Done! You may need to force push with: git push origin --force --all"
