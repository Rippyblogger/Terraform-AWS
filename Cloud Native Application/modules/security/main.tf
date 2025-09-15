resource "aws_security_group" "allow_internal_traffic" {
  name        = "Allow Internal traffic"
  description = "Allow ports"
  vpc_id      = var.main_vpc_id

  tags = {
    Name = "sg_allow_internal_access"
  }
}

#Create internal VPC traffic ingress rule between instances
resource "aws_vpc_security_group_ingress_rule" "f" {

  security_group_id = aws_security_group.allow_internal_traffic.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "sg_allow_internal"

  tags = {
    Name = "Allow Internal traffic"
  }
  lifecycle {
    create_before_destroy = true
  }
}

#Allow ICMP
resource "aws_vpc_security_group_ingress_rule" "allow_icmp_traffic" {

  security_group_id = aws_security_group.allow_internal_traffic.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 8
  to_port           = -1
  ip_protocol       = "icmp"
  description       = "sg_allow_icmp"

  tags = {
    Name = "Allow pings"
  }
  lifecycle {
    create_before_destroy = true
  }
}

#Allow port traffic from external sources
resource "aws_security_group" "allow_port_traffic" {
  name        = "Allow ports"
  description = "Allow ports"
  vpc_id      = var.main_vpc_id

  tags = {
    Name = "sg-allow-ssh"
  }
}

#Create SSH ingress rule for bastion instance, for test purposes 0.0.0.0/0
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {

  security_group_id = aws_security_group.allow_port_traffic.id
  cidr_ipv4         = local.allowed_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH"

  tags = {
    Name = "sg-allow-ssh"
  }
  lifecycle {
    create_before_destroy = true
  }
}

#Create egress rule

resource "aws_vpc_security_group_egress_rule" "allow_egress" {
  security_group_id = aws_security_group.allow_port_traffic.id
  cidr_ipv4         = var.wildcard
  ip_protocol       = "-1"
}


#Create ingress rule to frontend ASG from Bastion jump server


resource "aws_security_group" "allow_bastion_connect" {
  name        = "Allow bastion connect"
  description = "Allows connectivity via bastion"
  vpc_id      = var.main_vpc_id

  tags = {
    Name = "sg-allow-bastion-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_bastion_ingress" {
  security_group_id = aws_security_group.allow_bastion_connect.id
  cidr_ipv4         = local.bastion_cidr_block
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow bastion SSH connection"

  tags = {
    Name = "sg-allow-bastion-ssh"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_bastion_egress" {
  security_group_id = aws_security_group.allow_bastion_connect.id
  cidr_ipv4         = var.wildcard
  ip_protocol       = "-1"
}

//DB instance SG and rules

resource "aws_security_group" "allow_mongodb_connect" {
  name        = "Allow mongodb connect"
  vpc_id      = var.main_vpc_id

  tags = {
    Name = "sg-allow-mongodb-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_bastion_ingress_db" {
  security_group_id = aws_security_group.allow_mongodb_connect.id
  cidr_ipv4         = local.bastion_cidr_block
  from_port         = 27017
  to_port           = 27017
  ip_protocol       = "tcp"
  description       = "Allow mongodb connection"

  tags = {
    Name = "sg-allow-mongodb"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_db_egress" {
  security_group_id = aws_security_group.allow_mongodb_connect.id
  cidr_ipv4         = local.bastion_cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_to_db" {

  security_group_id = aws_security_group.allow_mongodb_connect.id
  cidr_ipv4         = local.bastion_cidr_block
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH"

  tags = {
    Name = "sg-allow-ssh"
  }
  lifecycle {
    create_before_destroy = true
  }
}
