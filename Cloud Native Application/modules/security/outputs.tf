# output "alb_sg" {
#   value = aws_security_group.alb.id
# }

output "allow_ssh_sg" {
  value = aws_security_group.allow_port_traffic.id
}

output "allow_internal_sg" {
  value = aws_security_group.allow_internal_traffic.id
}

output "allow_bastion_ingress" {
  value = aws_security_group.allow_bastion_connect.id
}