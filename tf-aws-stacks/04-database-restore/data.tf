data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

data "aws_subnets" "db" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["db"]
  }
}

# Reuse the DB security group from Stack 2 so the same app servers may connect
data "aws_security_group" "db" {
  vpc_id = data.aws_vpc.this.id
  name   = "${var.project_name}-db-sg"
}
