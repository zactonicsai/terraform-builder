variable "name" {
  description = "Base name for the instance(s). A numeric suffix is added when instance_count > 1."
  type        = string
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "launch_template_id" {
  description = "Launch template ID to launch from"
  type        = string
}

variable "launch_template_version" {
  description = "Launch template version: a number, \"$Latest\" or \"$Default\""
  type        = string
  default     = "$Latest"
}

variable "subnet_ids" {
  description = "Subnets to place instances in. Instances are distributed round-robin."
  type        = list(string)
}

# ---- Optional overrides of values in the launch template ----
variable "instance_type" {
  description = "Override instance type"
  type        = string
  default     = null
}

variable "ami" {
  description = "Override AMI"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Override key pair"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Override security groups"
  type        = list(string)
  default     = null
}

variable "iam_instance_profile" {
  description = "Override IAM instance profile name"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Override user data (plain text)"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Recreate the instance when user data changes"
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "Override public IP assignment"
  type        = bool
  default     = null
}

variable "private_ips" {
  description = "Optional fixed private IPs, one per instance"
  type        = list(string)
  default     = []
}

variable "create_eip" {
  description = "Allocate and attach an Elastic IP to each instance"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Override root volume size (GiB)"
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags applied to instances and EIPs"
  type        = map(string)
  default     = {}
}
