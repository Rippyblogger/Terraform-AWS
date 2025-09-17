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

#cloud-init template 

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      set -euo pipefail

      echo "Updating apt cache..."
      apt-get -y update

      echo "Installing prerequisites..."
      apt-get -y install nginx jq curl tar

      ALB_DNS=${var.alb_dns_name}
      MONGODB_PRIVATEIP=${var.mongodb_ip}

      mkdir -p /tmp/cloudacademy-app
      cd /tmp/cloudacademy-app

      echo "==========================="
      echo "FRONTEND - download latest release and install..."
      mkdir -p ./voteapp-frontend-react-2020
      pushd ./voteapp-frontend-react-2020
      curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest \
        | jq -r '.assets[0].browser_download_url' | xargs curl -OL
      INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest \
        | jq -r '.assets[0].name')
      tar -xvzf $INSTALL_FILENAME
      rm -rf /var/www/html
      cp -R build /var/www/html
      cat > /var/www/html/env-config.js << EOFF
      window._env_ = {REACT_APP_APIHOSTPORT: "$ALB_DNS"}
      EOFF
      popd

      echo "==========================="
      echo "API - download latest release, install, and configure systemd..."
      mkdir -p ./voteapp-api-go
      pushd ./voteapp-api-go
      curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest \
        | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url' \
        | xargs curl -OL
      INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest \
        | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .name')
      tar -xvzf $INSTALL_FILENAME

      # Move binary to /usr/local/bin
      cp ./api /usr/local/bin/voteapp-api
      popd

      # Create systemd service for API
      cat > /etc/systemd/system/voteapp-api.service << EOFF
      [Unit]
      Description=VoteApp Go API
      After=network.target

      [Service]
      ExecStart=/usr/local/bin/voteapp-api
      Restart=always
      Environment="MONGO_CONN_STR=mongodb://$${MONGODB_PRIVATEIP}:27017/langdb"
      WorkingDirectory=/tmp/cloudacademy-app/voteapp-api-go
      StandardOutput=journal
      StandardError=journal
      User=root

      [Install]
      WantedBy=multi-user.target
      EOFF

      echo "Reloading systemd and enabling services..."
      systemctl daemon-reload
      systemctl enable --now voteapp-api
      systemctl restart nginx

      echo "Setup finished: fin v1.00!"
    EOF
  }
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

  ebs_optimized                        = true
  image_id                             = data.aws_ami.ubuntu.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.ssh_key
  user_data                            = data.template_cloudinit_config.config.rendered

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.allow_internal_sg, var.allow_bastion_ingress]
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
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 180
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = [var.private_subnet_1, var.private_subnet_2]
  target_group_arns = [
    var.frontend_tg_arn,
    var.api_tg_arn
  ]
  launch_template {
    id      = aws_launch_template.frontend_instances.id
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
