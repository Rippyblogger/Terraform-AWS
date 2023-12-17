output "azs" {
  value = data.aws_availability_zones.azs.names
}

output "eip_1" {
  value = aws_eip.elastic_ips[0].public_dns
}

output "eip_2" {
  value = aws_eip.elastic_ips[1].public_dns
}