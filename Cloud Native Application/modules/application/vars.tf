variable "environment" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "alb_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "main_vpc_id" {
  type = string
}