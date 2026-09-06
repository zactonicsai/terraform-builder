# ---------- Secret: username + password in AWS Secrets Manager ----------
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/db-credentials"
  description             = "Login for the ${var.name} PostgreSQL database"
  recovery_window_in_days = 0 # delete immediately on destroy (demo-friendly)

  tags = { Name = "${var.name}-db-secret" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    port     = var.db_port
  })
}

# ---------- Security group the APP SERVERS will wear ----------
# Created here so the DB security group can point at it. The compute
# stack looks it up by name and attaches it to its launch template.
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App servers: website from inside the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-app-sg" }
}

# ---------- Security group for the database ----------
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "PostgreSQL from app servers only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-db-sg" }
}

# ---------- Subnet group (needs 2 AZs) ----------
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "${var.name}-db-subnets" }
}

# ---------- The PostgreSQL database ----------
resource "aws_db_instance" "this" {
  identifier        = "${var.name}-db"
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  port              = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = { Name = "${var.name}-db" }
}
