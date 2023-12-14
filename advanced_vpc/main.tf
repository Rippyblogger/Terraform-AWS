#VPC

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}


#Subnets

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available_zones.names[index(values(var.public_subnets), each.value)]
  map_public_ip_on_launch = true

  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "private_subnets" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available_zones.names[index(values(var.private_subnets), each.value)]
  map_public_ip_on_launch = false

  tags = {
    Name = each.key
  }
}

#Internet and NAT Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main VPC Internal Gateway"
  }
}

#EIP

resource "aws_eip" "lb" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_nat_gateway" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnets[element(keys(var.public_subnets), 0)].id

  tags = {
    Name = "Public subnet 1 NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

#Route

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.wildcard
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Main VPC public route table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.wildcard
    gateway_id = aws_nat_gateway.public_nat_gateway.id
  }

  tags = {
    Name = "Main VPC private route table"
  }
}

resource "aws_route_table_association" "public_route_association" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_association" {
  for_each       = aws_subnet.private_subnets
  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_security_group" "nginx_servers" {
  name        = "allow__http_ssh"
  description = "Allow ssh and http traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "ssh to VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.wildcard]
  }

  ingress {
    description = "http to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.wildcard]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.wildcard]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "http to private instances"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.wildcard]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [aws_security_group.nginx_servers.id]
  }

  tags = {
    Name = "allow_http"
  }
}


#Application load balancer
resource "aws_lb" "nginx_alb" {
  name               = "nginx-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  ip_address_type    = "ipv4"

  tags = {
    Name        = "nginx_alb_tf"
    Environment = "Test"
  }
}

#Target group
resource "aws_lb_target_group" "nginx_target_group" {
  name     = "nginx-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

#Listener

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

resource "aws_lb_listener_rule" "nginx_listener_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 99
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

#Keypair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key)
}

#Instance config

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-0fc5d935ebf8bc3bc"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_launch_template" "nginx_template" {
  name                   = "Nginx"
  image_id               = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.deployer.key_name
  user_data              = filebase64("${path.module}/ec2.userdata")
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.nginx_servers.id]

  tags = {
    Name = "Nginx webserver"
  }

}

#Autoscaling group

resource "aws_autoscaling_group" "bar" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.nginx_target_group.arn]
  vpc_zone_identifier = [aws_subnet.private_subnets[element(keys(var.private_subnets), 0)].id, aws_subnet.private_subnets[element(keys(var.private_subnets), 0)].id]

  launch_template {
    id      = aws_launch_template.nginx_template.id
    version = "$Latest"
  }
}
