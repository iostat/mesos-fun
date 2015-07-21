#!/bin/sh

# arguments are $1: this master's number
#               $2: total number of masters

echo "Initializing ZooKeeper node with ID $1"
sudo -u zookeeper zookeeper-server-initialize --myid=$1

for n in $(seq 1 $2); do
    echo "server.$n=10.0.0.$((n+10)):2888:3888" >> /etc/zookeeper/conf/zoo.cfg
done;

service zookeeper-server start
chkconfig zookeeper-server on
