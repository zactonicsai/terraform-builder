# Stack 4 (optional): restore a database from a snapshot with a NEW password.
# Needs Stack 1 (network) and Stack 2 (the db security group). A snapshot of
# demo-db must exist; see TUTORIAL.md for the one-line command to make one.
module "restored_db" {
  source = "../modules/rds_from_snapshot"

  name                   = var.project_name
  identifier             = var.restored_identifier
  snapshot_identifier    = var.snapshot_identifier
  source_db_identifier   = var.source_db_identifier
  db_subnet_ids          = data.aws_subnets.db.ids
  vpc_security_group_ids = [data.aws_security_group.db.id]
  instance_class         = var.instance_class
  password_length        = var.password_length
}
