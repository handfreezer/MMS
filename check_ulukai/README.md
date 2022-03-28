Here is load and mem from the famous Manubulon perl scripts.
About the check_disk.pl : it is a specific implementation where you give a list of path with warning and critical value, but the script is doing a "path reduce" on the list of path given in parameter... This optimise the size of perfdata based on mount point of each path.
Here I still need to write a clean wrapper over cpu and mem.