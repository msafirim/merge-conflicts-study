#!/bin/bash

if [ ! $1 ]; then
   printf "\n   USAGE: extract_conflicting_versions.sh [1_Merge_With_Conflicts.csv] \n\n"
   exit
fi

git_dir="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

if [ "$git_dir" ]; then
  continue
else
  printf "\n   Not a git repository \n\n"
  exit
fi

# make sure you are in a master branch
git checkout master

IFS="," # depends on separator you use

if [ -f 2_Conflicting_Versions.csv ]; then
  rm 2_Conflicting_Versions.csv
else
  echo "Merge commit SHA,Parent1,Parent2,Merge Date,File,Topic Branch Version,Mainline Version" > 2_Conflicting_Versions.csv
fi

sed 1d $1 | while read -r merge_sha parent1 parent2 merge_date
do
    parent_ref1=$parent1
    parent_ref2=$parent2
    merge_base="$(git merge-base --all --octopus $merge_sha^{1..2})"

    git checkout $parent_ref1

    merge_status="$(git merge --no-commit --no-ff -s recursive -Xignore-space-change -Xignore-space-at-eol -Xignore-all-space -Xdiff-algorithm=patience $parent_ref2 2>&1)"

    success=$?

    # success_msg="Automatic merge went well; stopped before committing as requested"

    # if [[ $success -eq 0 && "${merge_status}" == "$success_msg" ]]; then
    if [[ $success -eq 0 ]]; then
		    echo -e "\nMERGE COMMIT $merge_sha HAD NO CONFLICT\n"
		    printf "\n#### MERGE COMMIT \"$(git show -s --format=%s $merge_sha) - $merge_sha\" HAD NO CONFLICT ####\n\n"

        echo -n -e "\nDo you want to continue [y/n]? "
        # read ans
        read ans </dev/tty

  			if echo "$ans" | grep -iq "^y" ;then
  				git merge --abort
  				git checkout $current_branch
  			    continue
  			else
  				git merge --abort
  				git checkout $current_branch
  			    break
  			fi
		else
      printf "\n#### MERGE COMMIT \"$(git show -s --format=%s $merge_sha) - $merge_sha\" HAD CONFLICT ####\n\n"

			git diff --name-only --diff-filter=U > tmp_conflicts.txt

  		while read -r fname; do
  			touch tmp_topic_branch_changes.txt

  			echo "$(git diff --word-diff=porcelain $merge_base:$fname $parent1:$fname)" > tmp_topic_branch_diff.txt

  			echo "$(sed '/+++/d' tmp_topic_branch_diff.txt)" > topic_branch_diff.txt

  			while read -r line
  			do

  				if [[ "$line" == "+"* ]]; then

  					tmp_change="$(echo "$line" | awk -F'+' '{print $2}')"

  					if grep -q "$tmp_change" tmp_topic_branch_changes.txt; then
  				    	continue
  				    else
  				    	echo "$tmp_change" >> tmp_topic_branch_changes.txt
  				    fi
  				fi
  			done < topic_branch_diff.txt

  			# Remove duplicate changes in topic_branch version
  			awk '!a[$0]++' tmp_topic_branch_changes.txt > topic_branch_changes.txt

  			touch tmp_extracted_version.csv

  			  sed '/^[ \t]*$/d' "$fname" | while read -r line
  			  do
  			  	# Remove empty lines
  			  	line_array[$index]="$line"
      			index=$(($index+1))

  			    if echo "$line" | grep -q "<<<<<<< MINE"; then
  			      track=1
  			      continue
  				elif echo "$line" | grep -q ">>>>>>> YOURS"; then
  			      track=0

  				  topic_branch_ver="$(echo "$t" | awk -F'=======' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1);gsub("\"","\"\"",$1); print $1}')"
  			      mainline_ver="$(echo "$t" | awk -F'=======' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2);gsub("\"","\"\"",$2);print $2}')"

  					if [[ $topic_branch_ver = *[!\ ]* ]] && [[ $mainline_ver = *[!\ ]* ]] && [[ $topic_branch_ver != $mainline_ver ]] ; then

              if [[ $(wc -l < 2_Conflicting_Versions.csv) -ge 1 ]]; then
              	sed -e's/ \{1,\}/ /g' 2_Conflicting_Versions.csv > trim_extracted_conflicts.txt
              fi

  						while read -r line2
  						do
  							trim_topic_branch="$(echo "$topic_branch_ver" | sed -e's/ \{1,\}/ /g')"
  							trim_mainline="$(echo "$mainline_ver" | sed -e's/ \{1,\}/ /g')"

  							line2_with_quote="$(echo "$line2" | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/,"");gsub("\"","\"\""); print}' | sed -e's/ \{1,\}/ /g')"

  							if echo "$trim_topic_branch" | grep -q "$line2_with_quote"; then

  								conflicting_versions="$(echo "\"$trim_topic_branch\",,\"$trim_mainline\"")"

  								if grep -q "$conflicting_versions" trim_extracted_conflicts.txt; then
  									echo "$(sed "/$line2/d" topic_branch_changes.txt)" > topic_branch_changes.txt
  								else
  					        echo "$merge_sha,$parent1,$parent2,$merge_date,$fname,\"$topic_branch_ver\",\"$mainline_ver\"" >> tmp_extracted_version.csv
  									echo "$(sed "/$line2/d" topic_branch_changes.txt)" > topic_branch_changes.txt
  								fi
  							fi

  						done < topic_branch_changes.txt

  						rm trim_extracted_conflicts.txt
  					fi

  				  	t=''

  			    fi

  			    if [[ "$track" = 1 ]]; then
  			      t="$t$line "
  			    fi
  			  done

  			awk '!a[$0]++' tmp_extracted_version.csv >> 2_Conflicting_Versions.csv

  			rm topic_branch_diff.txt tmp_topic_branch_diff.txt topic_branch_changes.txt tmp_topic_branch_changes.txt tmp_extracted_version.csv

  		done < tmp_conflicts.txt

      rm tmp_conflicts.txt

		  git merge --abort
			git checkout master

		fi
done

printf "\n END OF ANALYSIS. \n You should find a file named 2_Conflicting_Versions.csv in a root of the project under study \n"
