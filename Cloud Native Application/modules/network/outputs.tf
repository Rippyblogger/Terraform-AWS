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

output "igw_id" {
  value = aws_internet_gateway.main_igw.id
}

output "nat_1" {
  value = aws_nat_gateway.nat_gateway[0].id
}

output "nat_2" {
  value = aws_nat_gateway.nat_gateway[1].id
}

output "public_subnets" {
  # value = aws_subnet.public_subnets
  value = [ for subnet in aws_subnet.public_subnets: subnet.id]
}

output "private_subnets" {
  value = aws_subnet.private_subnets
}

output "public_route_table" {
  value = aws_route_table.public_route_table
}

output "private_route_table" {
  value = aws_route_table.private_route_table
}