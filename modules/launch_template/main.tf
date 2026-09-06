terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  use_network_interface = var.associate_public_ip_address != null
}

resource "aws_launch_template" "this" {
  name                    = var.name
  description             = var.description
  image_id                = var.image_id
  instance_type           = var.instance_type
  key_name                = var.key_name
  ebs_optimized           = var.ebs_optimized
  disable_api_termination = var.disable_api_termination
  update_default_version  = var.update_default_version
  user_data               = var.user_data != null ? base64encode(var.user_data) : null

  # Security groups go either directly on the template or inside the
  # network_interfaces block — AWS does not allow both.
  vpc_security_group_ids = local.use_network_interface ? null : var.vpc_security_group_ids

  dynamic "network_interfaces" {
    for_each = local.use_network_interface ? [1] : []
    content {
      associate_public_ip_address = var.associate_public_ip_address
      security_groups             = var.vpc_security_group_ids
      subnet_id                   = var.subnet_id
      delete_on_termination       = true
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        delete_on_termination = block_device_mappings.value.delete_on_termination
        encrypted             = block_device_mappings.value.encrypted
        kms_key_id            = block_device_mappings.value.kms_key_id
        iops                  = block_device_mappings.value.iops
        throughput            = block_device_mappings.value.throughput
      }
    }
  }

  monitoring {
    enabled = var.monitoring_enabled
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.http_tokens
    http_put_response_hop_limit = var.http_put_response_hop_limit
  }

  dynamic "tag_specifications" {
    for_each = length(var.instance_tags) > 0 ? ["instance", "volume", "network-interface"] : []
    content {
      resource_type = tag_specifications.value
      tags          = var.instance_tags
    }
  }

  tags = var.tags
}
