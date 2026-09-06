data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  secret_name  = var.secret_name != "" ? var.secret_name : "${var.name}/keycloak-credentials"
  download_url = var.download_url != "" ? var.download_url : "https://github.com/keycloak/keycloak/releases/download/${var.keycloak_version}/keycloak-${var.keycloak_version}.tar.gz"
}

# ---------- Passwords Keycloak will be born with ----------
resource "random_password" "admin" {
  length  = 20
  special = false
}

resource "random_password" "nifi_client_secret" {
  length  = 32
  special = false
}

resource "random_password" "nifi_user" {
  length  = 16
  special = false
}

# ---------- Secret: everything NiFi and you need to log in ----------
resource "aws_secretsmanager_secret" "keycloak" {
  name                    = local.secret_name
  description             = "Keycloak admin login and the '${var.nifi_client_id}' OIDC client for realm '${var.realm_name}'"
  recovery_window_in_days = 0

  tags = { Name = "${var.name}-keycloak-secret" }
}

resource "aws_secretsmanager_secret_version" "keycloak" {
  secret_id = aws_secretsmanager_secret.keycloak.id
  secret_string = jsonencode({
    admin_username     = var.admin_username
    admin_password     = random_password.admin.result
    realm              = var.realm_name
    nifi_client_id     = var.nifi_client_id
    nifi_client_secret = random_password.nifi_client_secret.result
    nifi_user          = var.nifi_user
    nifi_user_password = random_password.nifi_user.result
    nifi_user_email    = var.nifi_user_email
    public_url         = var.public_url
  })
}

# ---------- Security group: Keycloak HTTP from inside the VPC ----------
resource "aws_security_group" "keycloak" {
  name        = "${var.name}-keycloak-sg"
  description = "Keycloak HTTP from the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-keycloak-sg" }
}

# ---------- IAM: read two secrets, fetch the tarball, allow Session Manager ----------
resource "aws_iam_role" "keycloak" {
  name = "${var.name}-keycloak-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "keycloak" {
  name = "${var.name}-keycloak-policy"
  role = aws_iam_role.keycloak.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_secret_arn, aws_secretsmanager_secret.keycloak.arn]
      }],
      var.artifact_bucket != "" ? [{
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.artifact_bucket}/*"
      }] : []
    )
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.keycloak.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "keycloak" {
  name = "${var.name}-keycloak-profile"
  role = aws_iam_role.keycloak.name
}

# ---------- The launch template ----------
resource "aws_launch_template" "keycloak" {
  name_prefix   = "${var.name}-keycloak-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = concat([aws_security_group.keycloak.id], var.extra_security_group_ids)

  iam_instance_profile {
    name = aws_iam_instance_profile.keycloak.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region             = var.region
    artifact_bucket    = var.artifact_bucket
    artifact_key       = var.artifact_key
    download_url       = local.download_url
    db_endpoint        = var.db_endpoint
    db_port            = var.db_port
    db_secret_arn      = var.db_secret_arn
    db_admin_database  = var.db_admin_database
    keycloak_db_name   = var.keycloak_db_name
    kc_secret_arn      = aws_secretsmanager_secret.keycloak.arn
    http_port          = var.http_port
    public_url         = var.public_url
    realm_name         = var.realm_name
    nifi_client_id     = var.nifi_client_id
    redirect_uris_json = jsonencode(var.nifi_redirect_uris)
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-keycloak" }
  }

  tags = { Name = "${var.name}-keycloak-lt" }
}
