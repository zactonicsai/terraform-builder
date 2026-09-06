# ---------- 1. Find the snapshot ----------
# If no exact snapshot was given, look up the newest one for the source DB.
data "aws_db_snapshot" "latest" {
  count = var.snapshot_identifier == "" ? 1 : 0

  db_instance_identifier = var.source_db_identifier
  most_recent            = true
}

locals {
  snapshot_id = var.snapshot_identifier != "" ? var.snapshot_identifier : data.aws_db_snapshot.latest[0].id
  secret_name = var.secret_name != "" ? var.secret_name : "${var.name}/${var.identifier}-credentials"
}

# ---------- 2. Invent a brand-new password ----------
resource "random_password" "db" {
  length           = var.password_length
  special          = true
  override_special = "!#$%^&*()-_=+" # avoid / @ " and space, which RDS rejects
}

# ---------- 3. Subnet group for the restored DB ----------
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "${var.identifier}-subnets" }
}

# ---------- 4. Restore the database from the snapshot ----------
# Engine, version, storage size, db_name and master USERNAME all come from
# the snapshot and cannot be changed here. The PASSWORD can be reset, so we
# set it to the new random one.
resource "aws_db_instance" "restored" {
  identifier          = var.identifier
  snapshot_identifier = local.snapshot_id
  instance_class      = var.instance_class
  password            = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_final_snapshot

  tags = { Name = var.identifier }
}

# ---------- 5. Store the new password in Secrets Manager ----------
resource "aws_secretsmanager_secret" "db" {
  name                    = local.secret_name
  description             = "Login for ${var.identifier} (restored from ${local.snapshot_id})"
  recovery_window_in_days = 0

  tags = { Name = "${var.identifier}-secret" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = aws_db_instance.restored.username # inherited from the snapshot
    password = random_password.db.result
    host     = aws_db_instance.restored.address
    port     = aws_db_instance.restored.port
    dbname   = aws_db_instance.restored.db_name
    engine   = aws_db_instance.restored.engine
  })
}
