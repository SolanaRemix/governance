#!/usr/bin/env bash
set -euo pipefail

default_branch="${1:-main}"

git fetch origin "${default_branch}"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash changes before running sync."
  exit 1
fi

git switch "${default_branch}"
git pull --ff-only origin "${default_branch}"

mapfile -t repair_branches < <(git for-each-ref --format='%(refname:short)' "refs/remotes/origin/swarm-repair-*")

if [[ "${#repair_branches[@]}" -eq 0 ]]; then
  echo "No swarm-repair branches found."
  echo "Mode complete. Awaiting operator approval."
  exit 0
fi

for branch_ref in "${repair_branches[@]}"; do
  echo "Merging ${branch_ref} into ${default_branch}"
  if ! git merge --no-edit "${branch_ref}"; then
    echo "Merge failed for ${branch_ref}."
    git merge --abort || true
    exit 1
  fi
done

git push origin "${default_branch}"

for branch_ref in "${repair_branches[@]}"; do
  branch_name="${branch_ref#origin/}"
  branch_name="${branch_name#refs/remotes/origin/}"
  echo "Deleting remote branch ${branch_name}"
  git push origin --delete "${branch_name}" || true
done

echo "Mode complete. Awaiting operator approval."
