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
  source             = "./modules/security"
  wildcard           = var.wildcard
  environment        = var.environment
  main_vpc_id        = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr
  workstation_ip     = var.workstation_ip
  bastion_private_ip = module.bastion.bastion_private_ip
}

module "bastion" {
  source            = "./modules/bastion"
  subnet_id         = module.network.public_subnet_1
  allow_ssh_sg      = module.security.allow_ssh_sg
  allow_internal_sg = module.security.allow_internal_sg
  public_ssh_key    = var.ssh_key

}

module "application" {
  source                = "./modules/application"
  environment           = var.environment
  private_subnet_1      = module.network.private_subnet_1
  private_subnet_2      = module.network.private_subnet_2
  main_vpc_id           = module.network.vpc_id
  ssh_key               = module.bastion.ssh_key_name
  instance_type         = var.instance_type
  allow_internal_sg     = module.security.allow_internal_sg
  allow_bastion_ingress = module.security.allow_bastion_ingress
  mongodb_ip            = module.storage.mondgdb_ip
  alb_dns_name          = module.load_balancer.alb_dns_name
  frontend_tg_arn       = module.load_balancer.frontend_tg_arn
  api_tg_arn            = module.load_balancer.api_tg_arn
  depends_on            = [module.storage]
}

module "load_balancer" {
  source            = "./modules/load_balancer"
  public_subnet_1   = module.network.public_subnet_1
  public_subnet_2   = module.network.public_subnet_2
  allow_internal_sg = module.security.allow_internal_sg
  alb_sg            = module.security.alb_sg
  environment       = var.environment
  main_vpc_id       = module.network.vpc_id
}

module "storage" {
  source                   = "./modules/storage"
  allow_internal_sg        = module.security.allow_internal_sg
  allow_mongodb_connect_sg = module.security.allow_mongodb_connect
  private_subnet_1         = module.network.private_subnet_1
  ssh_key                  = module.bastion.ssh_key_name
}
