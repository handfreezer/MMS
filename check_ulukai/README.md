Here is load and mem from the famous Manubulon perl scripts.
About the check_disk.pl : it is a specific implementation where you give a list of path with warning and critical value, but the script is doing a "path reduce" on the list of path given in parameter... This optimise the size of perfdata based on mount point of each path.
Here I still need to write a clean wrapper over cpu and mem.

 ***IMPORTANT note*** : today I did a pull request on centreon/centreon-plugin from my own fork as I added an equivalent to my check_disk.pl by adding the option path-best-match option to snmp standard storage plugin module [handfreezer/centreon-plugins](https://github.com/handfreezer/centreon-plugins)
