#!/bin/sh

# arguments are $1: number of ZK servers

# by Nicholas Sushkin @ StackOverflow
# http://stackoverflow.com/a/17841619
function join { local IFS="$1"; shift; echo "$*"; }

declare -a ZK_SERVERS

for n in $(seq 1 $1); do
    ZK_SERVERS[$n]="10.0.0.$((n+10)):2181"
done;

echo zk://`join , "${ZK_SERVERS[@]}"`/mesos > /etc/mesos/zk
echo MARATHON_MASTER=\"zk://`join , "${ZK_SERVERS[@]}"`/mesos\" > /etc/sysconfig/marathon
