output "bastion_ip" {
    value = aws_instance.bastion_instance.public_ip
}