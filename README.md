# mesos-fun
This is a fun experiment with Google Compute Engine, GlusterFS, and Apache Mesos to create a scalable cloud computing cluster.
It is intended to fit within the confines of a free trial of Google Cloud Platform, and give you a basic expandable compute/storage
cluster to play around with.

## What does it do?
This spins up a 8-node mesos cluster. All nodes are `n1-standard-1` instances running CentOS 7.1.

Three nodes are "masters", and they:
 * are named `master[1-3]`
 * have IP addresses of `10.0.0.1[1-3]`
 * are running ZooKeeper and mesos-master, with ZK clustered across the instances
 * are running glusterfs-server
   *  with a 2TB persistent disk attached to them, which is mounted at `/mnt/bricks`
   *  create some folders under /mnt/bricks for bricks for the volumes they'll be exposing
   *  create replica-3 volumes named `postgres` and `storage` to be mounted on the Slaves for persistent storage

The other five nodes are "slaves", which:
  * are named `slave[1-5]`
  * have IP addresses of `10.0.0.2[1-5]`
  * run mesos-slave as worker nodes 
  * mount the Gluster volumes hosted on the Masters at `/storage/<volume_name>`

Since GCE doesn't provide a way to set static internal IPs when creating a VM instance, we use [Google's recommended hack][1] of static network routes and `--can-ip-forward` to create a manageable IP addressing scheme. Just in case you're managing other compute in this project (please don't do this!), all the VMs are assigned to a network named `mesos-fun` with the range `10.10.10.0/24`. Furthermore, `master1` gets a static IP assigned to it and some GCE firewall rules to allow traffic from your machine to manage the cluster.

## Sounds fun, how do I run this?
### Prerequisites
You'll need to following to run this example:
  * A Google Cloud Platform account (and if it's not the free trial, funds to pay for the instances)
  * A blank project for that account (with Compute Engine enabled)
  * Hashicorp's Terraform. You can get it from http://terraform.io/
  * cURL
  * Bash
  * Your `$PATH` properly set up to run all these wonderful things




<!-- References -->
[1]: https://cloud.google.com/compute/docs/instances-and-network#staticnetworkaddress
