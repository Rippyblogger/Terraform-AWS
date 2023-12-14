variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
}

variable "region" {
  type = string
}

variable "wildcard" {
  type = string
}

variable "public_key" {
  type = string
}