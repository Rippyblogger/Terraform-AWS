resource "aws_security_group" "instances" {
  name        = "allow_access"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.main_vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.wildcard]
  }

  ingress {
    description = "HTTP from VPC"
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
    Name        = "allow_access"
    environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name        = "alb_allow_access"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.main_vpc_id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.wildcard]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.instances.id]
  }

  tags = {
    Name        = "allow_access"
    environment = var.environment
  }
}
