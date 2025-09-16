output "alb_dns_name" {
    value = aws_lb.internal.dns_name
}

output "frontend_tg_arn" {
    value = aws_lb_target_group.frontend_target_group.arn
}

output "api_tg_arn" {
    value = aws_lb_target_group.api_target_group.arn
}