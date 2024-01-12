resource "aws_lb" "nginx_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_id]
  subnets = var.public_subnets


  tags = {
    environment = var.environment
  }
}

resource "aws_lb_target_group" "front_end" {
  name        = "${var.alb_name}-tg"
  target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.main_vpc_id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

#Add listener rule
resource "aws_lb_listener_rule" "nginx_lb_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

