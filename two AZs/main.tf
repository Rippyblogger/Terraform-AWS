# grab aws availability zones for us-east-1

data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Create subnets
resource "aws_subnet" "main" {
  for_each          = var.public_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[index(keys(var.public_subnets), each.key)]
  tags = {
    Name = each.key
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}_internet_gateway"
  }
}

/* resource "aws_internet_gateway_attachment" "igw-attachment" {
  internet_gateway_id = aws_internet_gateway.igw.id
  vpc_id              = aws_vpc.main.id
} */

resource "aws_security_group" "subnet" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP access"
    cidr_blocks = [var.wildcard]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

resource "aws_security_group" "subnet_https" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS access"
    cidr_blocks = [var.wildcard]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
}


resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.wildcard
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-route"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "main_route_association" {
  subnet_id      = aws_subnet.main[element(keys(var.public_subnets), 0)].id
  route_table_id = aws_route_table.main_route_table.id
}

# EC2 instance
# Get EC2 ami

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

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.public_key)
}

resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main[element(keys(var.public_subnets), 0)].id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id, aws_security_group.subnet.id, aws_security_group.subnet_https.id]
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = <<-EOF
  #!/bin/bash
  sudo apt-get update && sudo apt install -y nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx
  EOF

  tags = {
    Name = "Nginx Server"
  }
}


resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh to Instance"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_ssh"
  }
}

#EBS volume

resource "aws_ebs_volume" "nginx_volume" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 2

  tags = {
    Name = "NginxVolume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.nginx_volume.id
  instance_id = aws_instance.nginx.id
}
