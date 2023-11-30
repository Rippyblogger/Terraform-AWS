output "nginx_public_ip" {
  value = aws_instance.nginx.public_ip
}

output "nginx_public_dns" {
  value = aws_instance.nginx.public_dns
}