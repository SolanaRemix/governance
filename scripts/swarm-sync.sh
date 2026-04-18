#!/usr/bin/env bash
set -euo pipefail

default_branch="${1:-main}"

git fetch origin "${default_branch}"
git checkout "${default_branch}"
git pull --ff-only origin "${default_branch}"

mapfile -t repair_branches < <(git for-each-ref --format='%(refname:short)' "refs/remotes/origin/swarm-repair-*")

for branch_ref in "${repair_branches[@]}"; do
  echo "Merging ${branch_ref} into ${default_branch}"
  git merge --no-edit "${branch_ref}"
done

git push origin "${default_branch}"

for branch_ref in "${repair_branches[@]}"; do
  branch_name="${branch_ref#origin/}"
  echo "Deleting remote branch ${branch_name}"
  git push origin --delete "${branch_name}" || true
done

echo "Mode complete. Awaiting operator approval."
