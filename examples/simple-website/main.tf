terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------- Lookups ----------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Amazon Linux 2023 AMI via SSM public parameter
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- Security group ----------
resource "aws_security_group" "web" {
  name        = "${var.project}-web"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-web" }
}

# ---------- Launch template ----------
module "web_lt" {
  source = "../../modules/launch_template"

  name          = "${var.project}-lt"
  description   = "Nginx hello page"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh", {
    site_title = "${var.project} on EC2"
  })

  block_device_mappings = [{
    device_name = "/dev/xvda"
    volume_size = 10
  }]

  instance_tags = {
    Project = var.project
    Role    = "web"
  }

  tags = { Project = var.project }
}

# ---------- EC2 instance from the template ----------
module "web" {
  source = "../../modules/ec2"

  name                    = "${var.project}-web"
  instance_count          = 1
  launch_template_id      = module.web_lt.id
  launch_template_version = module.web_lt.latest_version
  subnet_ids              = data.aws_subnets.default.ids

  tags = { Project = var.project }
}
