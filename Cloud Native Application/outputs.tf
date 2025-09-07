output "public_ip"{
    value = module.bastion.bastion_public_ip
}

output "frontend_private_ips" {
  value = module.application.frontend_instances_ips
}