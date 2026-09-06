terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_instance" "this" {
  count = var.instance_count

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  subnet_id = element(var.subnet_ids, count.index)

  # Overrides — null means "use whatever the launch template says"
  instance_type               = var.instance_type
  ami                         = var.ami
  key_name                    = var.key_name
  vpc_security_group_ids      = var.vpc_security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = length(var.private_ips) > count.index ? var.private_ips[count.index] : null

  dynamic "root_block_device" {
    for_each = var.root_volume_size != null ? [1] : []
    content {
      volume_size = var.root_volume_size
      encrypted   = true
    }
  }

  tags = merge(var.tags, {
    Name = var.instance_count > 1 ? "${var.name}-${count.index + 1}" : var.name
  })

  lifecycle {
    # Prevent drift-driven replacement when the AMI in the template rolls forward
    ignore_changes = [ami]
  }
}

resource "aws_eip" "this" {
  count    = var.create_eip ? var.instance_count : 0
  instance = aws_instance.this[count.index].id
  domain   = "vpc"
  tags = merge(var.tags, {
    Name = "${var.name}-eip-${count.index + 1}"
  })
}
