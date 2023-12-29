output "alb_sg" {
  value = aws_security_group.alb.id
}

output "instances_sg" {
  value = aws_security_group.instances
}