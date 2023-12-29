output "azs" {
  value = data.aws_availability_zones.azs.names
}

output "eip_1" {
  value = aws_eip.elastic_ips[0].public_dns
}

output "eip_2" {
  value = aws_eip.elastic_ips[1].public_dns
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets
}

output "private_subnets" {
  value = aws_subnet.private_subnets
}