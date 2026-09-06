variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "demo"
}

variable "db_engine_version" {
  type    = string
  default = "17"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
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
  type    = number
  default = 80
}
