# Stack 2: PostgreSQL 17 + secret + security groups. Apply AFTER 01-network.
module "rds" {
  source = "../modules/rds"

  name              = var.project_name
  vpc_id            = data.aws_vpc.this.id
  vpc_cidr          = data.aws_vpc.this.cidr_block
  db_subnet_ids     = data.aws_subnets.db.ids
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_port           = var.db_port
  app_port          = var.app_port
}
