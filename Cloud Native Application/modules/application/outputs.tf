output "frontend_instances_ips" {
  value = data.aws_instances.asg_instances.private_ips
}