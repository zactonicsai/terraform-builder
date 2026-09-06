# Look up what Stacks 1 and 2 built.
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["app"]
  }
}

# The app security group was created by the database stack
data "aws_security_group" "app" {
  vpc_id = data.aws_vpc.this.id
  name   = "${var.project_name}-app-sg"
}

data "aws_db_instance" "this" {
  db_instance_identifier = "${var.project_name}-db"
}

data "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/db-credentials"
}
