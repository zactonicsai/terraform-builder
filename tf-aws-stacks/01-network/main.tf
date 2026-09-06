# Stack 1: the private network. Apply this FIRST.
module "vpc" {
  source = "../modules/vpc"

  name                = var.project_name
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  interface_endpoints = var.interface_endpoints
}
