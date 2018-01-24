#!/bin/bash

# Get current branch so that to checkout to it after checking merge 
current_branch="$(git rev-parse --abbrev-ref HEAD)"


echo "Merge,Parent1,Parent2,Merge Date" > mergeCommits.csv

for ref in $(git rev-list --merges HEAD); do
    # Get a list of the commit's parents
    parents="$(git log --pretty=%P -n 1 $ref)"

	# Merge date
	merge_date="$(git log --pretty=%ad -n 1 $ref)"

    # For now only merge commits with 2 parents. We'll We'll ignore merge 
    # commits with more than 2 parents

    if [ $(echo "$parents" | wc -w) -eq 2 ]; then

        parent_ref1="$(git rev-parse $ref^1)"
        parent_ref2="$(git rev-parse $ref^2)"
    fi

    echo "$ref,$parent_ref1,$parent_ref1,$merge_date" >> mergeCommits.csv
done

printf "\n END OF MERGE EXTRACTION \n"