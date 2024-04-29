#!/bin/bash

# Define the pattern to exclude
pattern='.*(feature\/|bugfix|\/hotfix\/|main|staging|master|development|release\/).*'

# Get all remote branches
remote_branches=$(git branch -r)

# Dry-run flag
dry_run=false

# Parse command line options
while getopts ":d" opt; do
  case $opt in
    d)
      dry_run=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Filter out branches matching the pattern
branches_to_delete=($(git branch -r | grep -Ev "$pattern"))

# Store branch names in a separate array
branch_names=()
for branch in "${branches_to_delete[@]}"; do
  branch_names+=("$(echo "$branch" | sed 's/^origin\///')")
done

# Print the branches that will be deleted
if [ ${#branch_names[@]} -gt 0 ]; then
  echo "Branches to be deleted:"
  for branch_name in "${branch_names[@]}"; do
    if [[ $dry_run == true ]]; then
      echo " - $branch_name"
    fi
  done
else
  echo "No branches to be deleted."
fi

# Delete the filtered branches
if [[ $dry_run == false ]]; then
  for branch_name in "${branch_names[@]}"; do
    echo "Deleting remote branch: '$branch_name'"
    git push origin --delete "$branch_name"
  done
  if [ ${#branch_names[@]} -gt 0 ]; then
    echo "Deleted remote branches not matching the pattern: '$pattern'"
  else
    echo "No branches deleted."
  fi
fi
