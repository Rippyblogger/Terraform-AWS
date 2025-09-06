//Get avaialable AZs
data "aws_availability_zones" "available" {
  state = "available"
}

//Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.main_vpc_cidr
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    "Name" = var.vpc_name
    "Environment" = var.environment
      }
}

//Create public subnets

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch  = true
  
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch  = true
  
  tags = {
    Name = "Public Subnet 2"
  }
}

//Create private subnets

resource "aws_subnet" "private_subnets_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch  = true
  
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnets_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch  = true
  
  tags = {
    Name = "Private Subnet 2"
  }
}

//IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

// Main IGW route

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.wildcard
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Main route table"
  }
}

resource "aws_route_table_association" "pub_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "pub_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.main_route_table.id
}
// Create two eips

resource "aws_eip" "nat_gw_1_eip" {
  domain   = "vpc"

  tags = {
    Name = "Eip public 1"
  }
}

resource "aws_eip" "nat_gw_2_eip" {
  domain   = "vpc"

  tags = {
    Name = "Eip public 2"
  }
}

// Create both NAT-GWs

resource "aws_nat_gateway" "nat_Gw_1" {
  allocation_id = aws_eip.nat_gw_1_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NAT GW 1"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_Gw_2" {
  allocation_id = aws_eip.nat_gw_2_eip.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "NAT GW 2"
  }

  depends_on = [aws_internet_gateway.igw]
}

//Create private subnet routes to NAT GWs

resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = var.wildcard
    nat_gateway_id = aws_nat_gateway.nat_Gw_1.id
  }

  tags = {
    Name = "Private route table 1"
  }
}

resource "aws_route_table_association" "pvt_subnet_1" {
  subnet_id      = aws_subnet.private_subnets_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "pvt_subnet_2" {
  subnet_id      = aws_subnet.private_subnets_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = var.wildcard
    nat_gateway_id = aws_nat_gateway.nat_Gw_2.id
  }

  tags = {
    Name = "Private route table 2"
  }
}