variable "main_vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "wildcard" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "ssh_key" {
  type = string
}

variable "workstation_ip" {
  type = string
}