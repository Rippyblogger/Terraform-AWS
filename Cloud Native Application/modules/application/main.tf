#Get ami
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

#Create launch template

resource "aws_launch_template" "frontend_instances" {
  name = "app_instances_LT"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  ebs_optimized = true
  image_id = data.aws_ami.ubuntu.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = var.instance_type
  key_name = var.ssh_key

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [var.allow_internal_sg, var.allow_bastion_ingress]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Application instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

}

# Create autoscaling group 
resource "aws_autoscaling_group" "frontend" {
  name                      = "Frontend Instances"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 180
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = [var.private_subnet_1, var.private_subnet_2]

  launch_template {
    id = aws_launch_template.frontend_instances.id
    version = "$Latest"
  }

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  tag {
    key                 = "Name"
    value               = "Frontend-ASG"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

}

//Obtain frontend instances IPs

data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:Name"
    values = ["Frontend-ASG"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_autoscaling_group.frontend]
}
