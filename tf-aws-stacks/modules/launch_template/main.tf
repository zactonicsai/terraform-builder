# Newest Amazon Linux 2023 AMI (read from a public SSM parameter)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- IAM role: the "badge" the servers wear ----------
resource "aws_iam_role" "instance" {
  name = "${var.name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permission 1: read the one database secret
resource "aws_iam_role_policy" "read_db_secret" {
  name = "${var.name}-read-db-secret"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.secret_arn
    }]
  })
}

# Permission 2: let Session Manager log in (no SSH, no public IP needed)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-app-profile"
  role = aws_iam_role.instance.name
}

# ---------- Pick the first-boot script ----------
locals {
  user_data_vars = {
    secret_arn  = var.secret_arn
    db_endpoint = var.db_endpoint
    db_port     = var.db_port
    db_name     = var.db_name
    region      = var.region
    app_port    = var.app_port
  }

  # inline > custom file > built-in
  user_data = (
    var.user_data != "" ? var.user_data :
    var.user_data_file != "" ? templatefile(var.user_data_file, local.user_data_vars) :
    templatefile("${path.module}/user_data.sh.tpl", local.user_data_vars)
  )
}

# ---------- The launch template ----------
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-app-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-app" }
  }

  tags = { Name = "${var.name}-app-lt" }
}
