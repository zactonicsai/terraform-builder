variable "name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "security_group_id" {
  description = "The app security group (created by the database stack)"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret with the DB username/password"
  type        = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type = string
}

variable "region" {
  type = string
}

variable "app_port" {
  type    = number
  default = 80
}

variable "user_data" {
  description = "Inline first-boot script. Empty = built-in CRUD website."
  type        = string
  default     = ""
}

variable "user_data_file" {
  description = "Path to a custom script template. Empty = built-in."
  type        = string
  default     = ""
}
