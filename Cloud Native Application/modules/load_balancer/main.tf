#Declare random id
resource "random_id" "suffix" {
  byte_length = 4
}

//Create ALB logging S3 bucket

resource "aws_s3_bucket" "lb_logs" {
  bucket        = lower("lb-logs-${var.environment}-${random_id.suffix.hex}")
  force_destroy = true


  tags = {
    Name        = "ALB bucket"
    Environment = var.environment
  }
}

// Create Load balancer

resource "aws_lb" "internal" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.allow_internal_sg, var.alb_sg]
  subnets            = [var.public_subnet_1, var.public_subnet_2]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "lb_access_log"
    enabled = true
  }

  tags = {
    Name = "internal-lb"
  }
}

//Frontend Target groups

resource "aws_lb_target_group" "frontend_target_group" {
  name        = "frontend-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.main_vpc_id
}

#API Target group
resource "aws_lb_target_group" "api_target_group" {
  name        = "api-tg"
  target_type = "instance"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.main_vpc_id
}

// Create listeners

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default (HTTP)"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}


// Grant permission to ALB to modify s3 bucket

resource "aws_s3_bucket_policy" "allow_alb_access_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite",
        Effect = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.lb_logs.arn}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.lb_logs.arn
      }
    ]
  })
}
