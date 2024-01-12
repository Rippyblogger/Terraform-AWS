output "eip_1" {
  value = "${module.network.eip_1}"
}

output "eip_2" {
  value = "${module.network.eip_2}"
}

output "public_subnets" {
  value = [ for item in module.network.public_subnets: item]
}