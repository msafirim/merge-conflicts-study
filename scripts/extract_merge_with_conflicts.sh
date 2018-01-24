#!/bin/bash

if [ ! $1 ]
then
   printf "\n   USAGE: extract_merge_with_conflicts.sh [0_Merge_Commits.csv] \n\n"
   exit
fi

# make sure you are in the master branch

# git checkout master

IFS="," # depends on separator you use

# Get current branch so that to checkout to it after checking merge
current_branch="$(git rev-parse --abbrev-ref HEAD)"


echo "Merge,Parent1,Parent2,Merge Date" > 1_Merge_With_Conflicts.csv

sed 1d $1 | while read -r merge_sha parent1 parent2 merge_date
do
	    parent_ref1=$parent1
        parent_ref2=$parent2

        git checkout $parent_ref1

        merge_status="$(git merge --no-commit --no-ff -s recursive -Xignore-space-change -Xignore-space-at-eol -Xignore-all-space -Xdiff-algorithm=patience $parent_ref2 2>&1)"

        success=$?

    	if [[ $success -eq 0 ]]; then
		    printf "\n#### MERGE COMMIT \"$(git show -s --format=%s $merge_sha) - $merge_sha\" HAD NO CONFLICT ####\n\n"
			git merge --abort
			git checkout $current_branch
			continue
		else
			printf "\n#### MERGE COMMIT \"$(git show -s --format=%s $merge_sha) - $merge_sha\" HAD CONFLICT ####\n\n"
			echo "$merge_sha,$parent1,$parent2,$merge_date" >> 1_Merge_With_Conflicts.csv
			git merge --abort
			git checkout $current_branch
			continue
		fi
done

# Abort merge check
# git merge --abort

# Switch to branch before merge check
# git checkout $current_branch

printf "\n END EXTRACTION OF MERGE WITH CONFLICTS \n"
