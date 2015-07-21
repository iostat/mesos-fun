#!/bin/sh

# simulates "interactive" fdisk (new partition, #1, <default start>, <default end>, write)
echo "n
p
1


w
" | fdisk /dev/sdb

# format new partition with xfs
mkfs.xfs -isize=512 /dev/sdb1

# make the mount point
mkdir -p /mnt/bricks

# add the fstab entry
echo "/dev/sdb1 /mnt/bricks xfs defaults 1 2" >> /etc/fstab

# reload fstab and automount the new partition
mount -a && mount

# create the folders for the postgres and storage bricks
mkdir -p /mnt/bricks/postgres
mkdir -p /mnt/bricks/storage
