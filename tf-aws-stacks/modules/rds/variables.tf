variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "engine_version" {
  type    = string
  default = "17"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "rcadmin"
}

variable "db_password" {
  type      = string
  default   = "changeme"
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "app_port" {
  description = "Port the website on the app servers listens on"
  type        = number
  default     = 80
}
