# Jini

Jini is a linux daemon which is used to analyze disk usage of a directory.
It will recursevely walk the the directory regardless of the depth.

# Functionality

- [ ] Add a job starting from a directory and a priority
    - Priority from (1 = Low, 2 = normal, 3 = high)
    - If another job is created for a subdirectory of an already running job
      the new job shouldn't create new tasks.
- [ ] Delete a job
- [ ] Suspend a job
- [ ] Resume a job
- [ ] State of all jobs
- [ ] Information of one job

# Example usage

```terminal
$> jini -a /home/user/my_repo -p 3
Created analysis task for '/home/user/my_repo' and priority 'high'.

$> jini -l
ID PRI  Path               Progress Status   Details
2  ***  /home/user/my_repo 45%      running  2306 files, 11 dirs

$> jini -i 2
Path               Usage Size Amount
/home/user/my_repo 100% 100MB #########################################
|
|-/repo1/          31.3% 31.3MB #############
|-/repo1/binaries/ 15.3% 15.3MB ######
|-/repo1/src/ 5.7% 5.7MB ##
|-/repo1/releases/ 9.0% 9.0MB ####
|
|-/repo2/          52.5% 52.5MB #####################
|-/repo2/binaries/ 45.4% 45.4MB ##################
|-/repo2/src/ 5.4% 5.4MB ##
|-/repo2/releases/ 2.2% 2.2MB #
|
|-/repo3/          17.2% 17.2MB ########
[...]

$> jini -a /home/user/my_repo/repo2
Directory 'home/user/my_repo/repo2' is already included in analysis with ID '2'

$> jini -S 2
Pausing analysis task with ID '2', for '/home/user/my_repo'

$> jini -R 2
Resuming analysis task with ID '2', for '/home/user/my_repo'

$> jini -r 2
Removed analysis task with ID '2', status 'done' for '/home/user/my_repo'

$> jini -i 2
No existing analysis for task ID '2'
```

# References

- https://clig.dev
