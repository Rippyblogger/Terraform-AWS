module "network" {
  source = "./modules/network"
  main_vpc_cidr = "10.0.0.0/16"
  vpc_name = "main_vpc"
  environment = "Testing"
  public_subnets = ["public_subnet 1", "public_subnet 2"]
  private_subnets = ["private_subnet 1", "private_subnet 2"]
  wildcard = "0.0.0.0/0"
}

module "security" {
  source = "./modules/security"
  wildcard = "0.0.0.0/0"
  environment = "Testing"
  main_vpc_id = module.network.vpc_id
}

module "application" {
  source = "./modules/application"
  alb_name = "nginx-alb"
  environment = "Testing"
  alb_id = module.security.alb_sg
  public_subnets = module.network.public_subnets
  main_vpc_id = module.network.vpc_id
}
