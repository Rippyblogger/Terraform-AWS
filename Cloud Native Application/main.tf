module "network" {
  source = "./modules/network"
  main_vpc_cidr = "10.0.0.0/16"
  vpc_name = "main_vpc"
  environment = "Testing"
  public_subnets = ["public_subnet 1", "public_subnet 2"]
  private_subnets = ["private_subnet 1", "private_subnet 2"]
  wildcard = "0.0.0.0/0"
}