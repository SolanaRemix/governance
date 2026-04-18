#!/usr/bin/env bash
set -euo pipefail

default_branch="${1:-main}"

git fetch origin "${default_branch}"
git checkout "${default_branch}"
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
    exit 1
  fi
done

git push origin "${default_branch}"

for branch_ref in "${repair_branches[@]}"; do
  branch_name="${branch_ref#origin/}"
  echo "Deleting remote branch ${branch_name}"
  git push origin --delete "${branch_name}" || true
done

echo "Mode complete. Awaiting operator approval."
