variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "demo"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "user_data" {
  description = "Inline first-boot script override. Empty = built-in CRUD website."
  type        = string
  default     = ""
}

variable "user_data_file" {
  description = "Path to a custom first-boot script template. Empty = built-in."
  type        = string
  default     = ""
}
