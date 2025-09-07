locals {
    allowed_ip = "${var.workstation_ip}/32"
    bastion_cidr_block = "${var.bastion_private_ip}/32"
}