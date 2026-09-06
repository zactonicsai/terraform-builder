data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  download_url = var.download_url != "" ? var.download_url : "https://archive.apache.org/dist/nifi/${var.nifi_version}/nifi-${var.nifi_version}-bin.zip"
}

# Password for NiFi's self-signed keystore and its sensitive-properties key
resource "random_password" "keystore" {
  length  = 20
  special = false
}

resource "random_password" "sensitive_props" {
  length  = 24
  special = false
}

# ---------- Security group: NiFi HTTPS from inside the VPC ----------
resource "aws_security_group" "nifi" {
  name        = "${var.name}-nifi-sg"
  description = "NiFi HTTPS from the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-nifi-sg" }
}

# ---------- IAM ----------
resource "aws_iam_role" "nifi" {
  name = "${var.name}-nifi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "nifi" {
  name = "${var.name}-nifi-policy"
  role = aws_iam_role.nifi.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.keycloak_secret_arn
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
  role       = aws_iam_role.nifi.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nifi" {
  name = "${var.name}-nifi-profile"
  role = aws_iam_role.nifi.name
}

# ---------- Launch template ----------
resource "aws_launch_template" "nifi" {
  name_prefix   = "${var.name}-nifi-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.nifi.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.nifi.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region              = var.region
    artifact_bucket     = var.artifact_bucket
    artifact_key        = var.artifact_key
    download_url        = local.download_url
    keycloak_secret_arn = var.keycloak_secret_arn
    keycloak_host       = var.keycloak_private_ip
    keycloak_port       = var.keycloak_http_port
    realm_name          = var.realm_name
    https_port          = var.https_port
    proxy_hosts         = join(",", var.proxy_hosts)
    keystore_password   = random_password.keystore.result
    sensitive_props_key = random_password.sensitive_props.result
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-nifi" }
  }

  tags = { Name = "${var.name}-nifi-lt" }
}
