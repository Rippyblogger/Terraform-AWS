variable "vpc_cidr_block" {
  type = string 
}

variable "public_subnets" {
  type = map(string)
}

variable "vpc_name" {
  type = string
}

variable "wildcard" {
  type = string
}

variable "public_key" {
  type = string
}