variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "hello-web"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach the site on port 80"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Optional SSH key pair name"
  type        = string
  default     = null
}
