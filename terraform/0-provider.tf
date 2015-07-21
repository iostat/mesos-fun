/*
 * 0-provider.tf
 * This file declares the cloud provider that terraform will use to 
 * to bring up the VM instances that power this system.
 *
 * Don't edit this file directly, instead change your appropriate options in 'terraform.tfvars'
 */

variable "account_file" {}
variable "project" {}
variable "region" {}

provider "google" {
    account_file = "${var.account_file}"
    project      = "${var.project}"
    region       = "${var.region}"
}
