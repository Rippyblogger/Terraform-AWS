output "bastion_public_ip" {
    value = aws_instance.bastion_instance.public_ip
}

output "bastion_private_ip" {
    value = aws_instance.bastion_instance.private_ip
}

output "ssh_key_name" {
    value = aws_key_pair.deployer.key_name
}