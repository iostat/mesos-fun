/*
 * 2-masters.tf
 * This file creates creates the master instances and performs the "static ip hack".
 */

variable "zone" {}
variable "ssh-identity" {}
variable "ssh-user" {}
variable "master-count" {}

resource "google_compute_disk" "gluster-disk" {
    name  = "master${count.index+1}-gluster"
    type  = "pd-standard"
    size  = 2000
    zone  = "${var.zone}"
    count = "${var.master-count}"
}

resource "google_compute_instance" "master" {
    name           = "master${count.index+1}"
    machine_type   = "n1-standard-1"
    zone           = "${var.zone}"
    can_ip_forward = true
    count          = "${var.master-count}"

    disk {
        type  = "pd-standard"
        size  = 100
        image = "centos-cloud/centos-7-v20150710"
    }

    disk {
        disk        = "${element(google_compute_disk.gluster-disk.*.name, count.index)}"
        auto_delete = false
    }

    network_interface {
        network = "${google_compute_network.our-network.name}"
        access_config {
            # blank access_config = ephemeral IP
        }
    }

    connection {
        type     = "ssh"
        user     = "${var.ssh-user}"
        key_file = "${var.ssh-identity}"
    }

    # copies a template file which gets replaced with the IP of this master
    # instead of having a huge multiline echo in this .tf
    provisioner "file" {
        source      = "templates/ifconfig-eth0-subif.template"
        destination = "/tmp/ifconfig-eth0-subif.template"
    }

    # Edits in the IP this node should have into the template file we just uploaded
    # Does some sorcery which CentOS requires to accept this sub-if
    # And enables it
    provisioner "remote-exec" {
        inline = [
            "sed -i s/REPLACEME/10.0.0.${count.index+11}/g /tmp/ifconfig-eth0-subif.template",
            "sudo mv /tmp/ifconfig-eth0-subif.template /etc/sysconfig/network-scripts/ifcfg-eth0:0",
            "echo NM_CONTROLLED=no | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0",
            "sudo ifup eth0:0",
            "sudo chkconfig network on"
        ]
    }

    # Uploads a script which creates a partition map and formats the first drive as XFS
    # creates /mnt/bricks, mounts the new partition there and adds it to XFS
    provisioner "file" {
        source      = "scripts/make-gluster-brick-storage.sh"
        destination = "/tmp/make-gluster-brick-storage.sh"
    }

    # Runs the above script 
    provisioner "remote-exec" {
        inline = ["sudo bash /tmp/make-gluster-brick-storage.sh"] 
    }

    # Install the EPEL repo for future maintainability
    # Additionally, install the Mesosphere repo (for mesos, marathon, and chronos)
    # and the Cloudera CDH4 repo (for ZK) while we're at it
    # As well as the Gluster repo
    # Then, install all the packages we'll need
    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y epel-release",
            "sudo rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm",
            "sudo rpm -Uvh http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm",
            "sudo wget -P /etc/yum.repos.d http://download.gluster.org/pub/gluster/glusterfs/LATEST/RHEL/glusterfs-epel.repo",
            "sudo yum update -y",
            "sudo yum install -y vim glusterfs-server zookeeper zookeeper-server mesos marathon chronos"
        ]
    }

    # Copy over a shell script to initialize ZooKeeper, then run it
    provisioner "file" {
        source      = "scripts/initialize-zookeeper.sh"
        destination = "/tmp/initialize-zookeeper.sh"
    }

    provisioner "remote-exec" {
        inline = ["sudo bash /tmp/initialize-zookeeper.sh ${count.index + 1} ${var.master-count}"]
    }

    # Copy over a shell script to initialize mesos-master, marathon, and chronos, then run it.
    # Since this script is also used to initialize the mesos-slaves,
    # starting the services is done inline
    provisioner "file" {
        source      = "scripts/initialize-mesos-marathon.sh"
        destination = "/tmp/initialize-mesos-marathon.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo bash /tmp/initialize-mesos-marathon.sh ${var.master-count}",
            "sudo service mesos-master start",
            "sudo chkconfig mesos-master on",
            "sudo service marathon start",
            "sudo chkconfig marathon on",
            "sudo service chronos start",
            "sudo chkconfig chronos on"
        ]
    }
}

resource "google_compute_route" "master-ip-hack" {
    name                   = "static-internal-ip-hack-master${count.index+1}"
    network                = "${google_compute_network.our-network.name}"
    priority               = 100
    dest_range             = "10.0.0.${count.index+11}/32"
    next_hop_instance      = "${element(google_compute_instance.master.*.name, count.index)}"
    next_hop_instance_zone = "${var.zone}"
    count                  = "${var.master-count}"
}
