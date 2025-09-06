module "network" {
  source          = "./modules/network"
  main_vpc_cidr   = var.main_vpc_cidr
  vpc_name        = var.vpc_name
  wildcard        = var.wildcard
  environment     = var.environment
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "security" {
  source         = "./modules/security"
  wildcard       = var.wildcard
  environment    = var.environment
  main_vpc_id    = module.network.vpc_id
  vpc_cidr_block = module.network.vpc_cidr
}

module "bastion" {
  source            = "./modules/bastion"
  subnet_id         = module.network.public_subnet_1
  allow_ssh_sg      = module.security.allow_ssh_sg
  allow_internal_sg = module.security.allow_internal_sg
  public_ssh_key    = var.ssh_key
}

# module "application" {
#   source = "./modules/application"
#   alb_name = "nginx-alb"
#   environment = "Testing"
#   alb_id = module.security.alb_sg
#   public_subnets = module.network.public_subnets
#   main_vpc_id = module.network.vpc_id
# }
