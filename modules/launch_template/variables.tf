variable "name" {
  description = "Name of the launch template"
  type        = string
}

variable "description" {
  description = "Launch template description"
  type        = string
  default     = null
}

variable "image_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Raw (plain text) user data script. The module base64-encodes it."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IP. When set (true/false) a network_interfaces block is used."
  type        = bool
  default     = null
}

variable "subnet_id" {
  description = "Optional subnet for the primary network interface (only used with associate_public_ip_address)"
  type        = string
  default     = null
}

variable "block_device_mappings" {
  description = "EBS volumes to attach"
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    iops                  = optional(number)
    throughput            = optional(number)
  }))
  default = []
}

variable "ebs_optimized" {
  description = "Enable EBS optimization"
  type        = bool
  default     = true
}

variable "monitoring_enabled" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "http_tokens" {
  description = "IMDS setting: required (IMDSv2 only) or optional"
  type        = string
  default     = "required"
}

variable "http_put_response_hop_limit" {
  description = "IMDS hop limit"
  type        = number
  default     = 1
}

variable "update_default_version" {
  description = "Make each new version the default"
  type        = bool
  default     = true
}

variable "instance_tags" {
  description = "Tags applied to instances and volumes launched from this template"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the launch template resource"
  type        = map(string)
  default     = {}
}
