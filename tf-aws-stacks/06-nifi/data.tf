data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Tier"
    values = [var.subnet_tier]
  }
}

data "aws_secretsmanager_secret" "keycloak" {
  name = var.keycloak_secret_name
}

# Find the Keycloak server by its Name tag (skipped if keycloak_private_ip is given)
data "aws_instance" "keycloak" {
  count = var.keycloak_private_ip == "" ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [var.keycloak_instance_name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

locals {
  keycloak_ip = var.keycloak_private_ip != "" ? var.keycloak_private_ip : data.aws_instance.keycloak[0].private_ip
}
