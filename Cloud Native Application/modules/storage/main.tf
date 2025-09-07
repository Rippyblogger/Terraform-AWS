data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create Bastion instance

resource "aws_instance" "mongodb_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_1
  vpc_security_group_ids = [var.allow_internal_sg]
  key_name = var.ssh_key

  tags = {
    Name = "MongoDB Instance"
  }

  associate_public_ip_address = true
}