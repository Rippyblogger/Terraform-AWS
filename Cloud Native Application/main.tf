module "network" {
  source          = "./modules/network"
  main_vpc_cidr   = "10.0.0.0/16"
  vpc_name        = "main_vpc"
  wildcard        = "0.0.0.0/0"
  environment     = "Production"
  public_subnets  = ["10.0.0.0/19", "10.0.32.0/19"]
  private_subnets = ["10.0.64.0/19", "10.0.96.0/19"]
}

# module "security" {
#   source      = "./modules/security"
#   wildcard    = "0.0.0.0/0"
#   environment = "Testing"
#   main_vpc_id = module.network.vpc_id
# }

# module "application" {
#   source = "./modules/application"
#   alb_name = "nginx-alb"
#   environment = "Testing"
#   alb_id = module.security.alb_sg
#   public_subnets = module.network.public_subnets
#   main_vpc_id = module.network.vpc_id
# }
