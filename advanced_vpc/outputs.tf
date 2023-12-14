output "security_group_load_balancer" {
  value = aws_security_group.load_balancer_sg
}

output "security_group_nginx_servers" {
  value = aws_security_group.nginx_servers
}

output "public_subnet_1" {
  value = aws_subnet.public_subnets[element(keys(var.public_subnets), 0)].id
}

output "private_subnet_1" {
  value = aws_subnet.private_subnets[element(keys(var.private_subnets), 0)].id
}

output "public_subnet_2" {
  value = aws_subnet.public_subnets[element(keys(var.public_subnets), 1)].id
}

output "private_subnet_2" {
  value = aws_subnet.private_subnets[element(keys(var.private_subnets), 1)].id
}

output "eip" {
  value = aws_eip.lb.public_ip
}