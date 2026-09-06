variable "name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "app_subnet_cidrs" {
  description = "Subnets for EC2 / ASG (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_subnet_cidrs" {
  description = "Subnets for RDS (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "region" {
  type = string
}

variable "interface_endpoints" {
  description = "AWS services reachable privately (no internet). secretsmanager is required by the app; ssm* let you log in with Session Manager."
  type        = list(string)
  default     = ["secretsmanager", "ssm", "ssmmessages", "ec2messages"]
}
