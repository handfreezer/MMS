# MMS
<h3>Monitoring-Metrologie-Supervision</h3>

Hello, This make many years (about from 2014), that I'm looking for the ideal monitoring system... And I'm steel searching it.

I have to say I found a solution, the one which is good for me but might not for you, so take care of the following. This place is just a place to share the most important part of my knowledge, but not the truth!

Over years, I discovered Nagios (Whaou!), And NetSaint... but also all forking of Nagios: most seen by me was Naemon (because pulling code in Nagios was mastered by only one person refusing some pulling over community requests), Shinken (as a POC of a new concept of threading for Nagios, and "copied" few months later), Icinga 1, ... but also others like Zabbix, Centreon, ... and now, I'm stuck with Icinga 2 and it's DSL (with coding purposes available!).

Also, as opensource is really nice (OK, you already know this!), There is the MonitoringPlugins for helping to create check commands, BUT, I found a very nice "like" project called : centreon-plugins and here I say : yes, opensource allow you to choose and use the best of each project. So I created few conf files to integrate this concept. (I feel like the tag reference as branch is not working but also not generating an error, and a big thanks to centreon-plugins project!)

An other point, I was bothered what it seems a simple problem now : what I noticed is that I'm wathcing CPU and RAM often at the same time. But checking those values with an interval of 2 or 5 minutes is a problem because perfdata is most of the time not synchronised. And this can change drastically my analyse, in better way if correctly synchronised. This is why I wrote a naive script for this.
