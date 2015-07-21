/*
 * 1-internal-network.tf
 * This file creates the mesos-fun network which our instances will be hooked up to.
 */

resource "google_compute_network" "our-network" {
    name       = "mesos-fun"
    ipv4_range = "10.10.10.0/24"
}

resource "google_compute_firewall" "allow-internal-traffic" {
    name          = "allow-internal-traffic"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["10.10.10.0/24"]

    allow {
        protocol = "icmp"
    }
    
    allow {
        protocol = "tcp"
	ports = ["1-65535"]
    }

    allow {
        protocol = "udp"
	ports = ["1-65535"]
    }
}

resource "google_compute_firewall" "allow-static-ip-hack-traffic" {
    name          = "allow-static-ip-hack-traffic"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["10.0.0.0/24"]

    allow {
        protocol = "icmp"
    }
    
    allow {
        protocol = "tcp"
	ports = ["1-65535"]
    }

    allow {
        protocol = "udp"
	ports = ["1-65535"]
    }
}

resource "google_compute_firewall" "allow-ssh" {
    name          = "allow-ssh"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "tcp"
	ports = [22]
    }
}

resource "google_compute_firewall" "allow-icmp" {
    name          = "allow-icmp"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "icmp"
    }
}

resource "google_compute_firewall" "allow-mesos-ui" {
    name          = "allow-mesos-ui"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "tcp"
	ports = [5050]
    }
}

resource "google_compute_firewall" "allow-marathon-ui" {
    name          = "allow-marathon-ui"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "tcp"
	ports = [8080]
    }
}

resource "google_compute_firewall" "allow-chronos-ui" {
    name          = "allow-chronos-ui"
    network       = "${google_compute_network.our-network.name}"
    source_ranges = ["0.0.0.0/0"]

    allow {
        protocol = "tcp"
	ports = [4400]
    }
}
