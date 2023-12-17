#VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.main_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.vpc_name
    environment = var.environment
  }
}

#internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.environment
  }
}

# Elastic IPs

resource "aws_eip" "elastic_ips" {
  for_each = {for item, value in var.public_subnets : item => value}
  domain = "vpc"
}

#NAT Gateways

resource "aws_nat_gateway" "nat_gateway" {
    for_each = {for item, value in var.public_subnets : item => value}
    allocation_id = aws_eip.elastic_ips[each.key].id
    subnet_id = aws_subnet.public_subnets[each.key].id
}

#Get Availability zones
data "aws_availability_zones" "azs" {
  state = "available"
}

#Create public subnets
resource "aws_subnet" "public_subnets" {
  for_each = {for subnet, value in var.public_subnets : subnet => value}
  vpc_id   = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.main_vpc_cidr, 8, index((var.public_subnets), each.value)+1)
  availability_zone = data.aws_availability_zones.azs.names[index(var.public_subnets, each.value)]

  tags = {
    Name        = each.value
    environment = var.environment
  }
}

#Create private subnets
resource "aws_subnet" "private_subnets" {
  for_each = {for subnet, value in var.private_subnets : subnet => value}
  vpc_id   = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(var.main_vpc_cidr, 8, index((var.private_subnets), each.value)+3)
  availability_zone = data.aws_availability_zones.azs.names[index(var.private_subnets, each.value)]

  tags = {
    Name        = each.value
    environment = var.environment
  }
}

#Route tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.wildcard
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table" "private_route_table" {
  for_each = {for subnet, value in var.private_subnets : subnet => value}
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.wildcard
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
}
}

resource "aws_route_table_association" "public_assoc" {
  for_each = {for subnet, value in var.public_subnets : subnet => value}
  subnet_id = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {for subnet, value in var.private_subnets : subnet => value}
  subnet_id = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_table[each.key].id
}