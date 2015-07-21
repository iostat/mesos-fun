/*
 * 3-slaves.tf
 * This file creates creates the slave instances and performs the "static ip hack".
 */

variable "slave-count" {}

resource "google_compute_instance" "slave" {
    name           = "slave${count.index+1}"
    machine_type   = "n1-standard-1"
    zone           = "${var.zone}"
    can_ip_forward = true
    count          = "${var.slave-count}"

    disk {
        type  = "pd-standard"
        size  = 100
        image = "centos-cloud/centos-7-v20150710"
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
            "sed -i s/REPLACEME/10.0.0.${count.index+111}/g /tmp/ifconfig-eth0-subif.template",
            "sudo mv /tmp/ifconfig-eth0-subif.template /etc/sysconfig/network-scripts/ifcfg-eth0:0",
            "echo NM_CONTROLLED=no | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0",
            "sudo ifup eth0:0",
            "sudo chkconfig network on"
        ]
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
            "sudo yum install -y vim glusterfs zookeeper mesos"
        ]
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
            "echo docker,mesos | sudo tee /etc/mesos-slave/containerizers",
            "sudo service mesos-slave start",
            "sudo chkconfig mesos-slave on",
        ]
    }
}

resource "google_compute_route" "slave-ip-hack" {
    name                   = "static-internal-ip-hack-slave${count.index+1}"
    network                = "${google_compute_network.our-network.name}"
    priority               = 100
    dest_range             = "10.0.0.${count.index+111}/32"
    next_hop_instance      = "${element(google_compute_instance.slave.*.name, count.index)}"
    next_hop_instance_zone = "${var.zone}"
    count                  = "${var.slave-count}"
}
