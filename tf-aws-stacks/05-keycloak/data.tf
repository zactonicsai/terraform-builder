# Everything here already exists; we only look it up.
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

data "aws_security_group" "db_client" {
  vpc_id = data.aws_vpc.this.id
  name   = var.db_client_security_group_name
}

data "aws_db_instance" "this" {
  db_instance_identifier = var.db_identifier
}

data "aws_secretsmanager_secret" "db" {
  name = var.db_secret_name
}
