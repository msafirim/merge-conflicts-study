## How to use the scripts
Note: You should run all the scripts in a project root directory. i.e `user@user-pc:~/project_repo$ script_path/script.sh`. Also, you should set permissions on the scripts i.e. `$ chmod +x script_path/script.sh`

#### Extract merges
1. Clone a project that you would like to extract and analyze merge conflicts.
2. You can checkout to a specific date using the following git command git checkout `git rev-list master -n 1 --first-parent --before=2017-09-05`. However, you can skip this step if you don't want to extract the merge conflicts from a specific date.
3. Run the following command to obtain data of merge commits. `$ script_path/extract_merges.sh`
4. You should find a file named `0_Merge_Commits.csv` in a project directory.

#### Extract merge with conflicts
1. Using the data from previous step, run the following command to obtain merge which had conflicts. `$ script_path/extract_merge_with_conflicts.sh 0_Merge_Commits`
2. You should find a file named `1_Merge_With_Conflicts.csv` in the project directory.

#### Extract conflicting versions in merge with conflicts
1. Run the command `$ script_path/extract_merge_with_conflicts.sh 1_Merge_With_Conflicts.csv`. Also, alternatively you can use `0_Merge_Commits.csv` obtained from the first step.
2. You should find a file named `2_Conflicting_Versions.csv` in the project directory.

