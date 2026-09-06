variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "demo"
}

# ---------- EXISTING resources ----------
variable "vpc_name" {
  type    = string
  default = "demo-vpc"
}

variable "subnet_tier" {
  type    = string
  default = "app"
}

variable "keycloak_instance_name" {
  description = "Name tag of the running Keycloak EC2 (its private IP is looked up)"
  type        = string
  default     = "demo-keycloak"
}

variable "keycloak_private_ip" {
  description = "Set this to skip the instance lookup (e.g. Keycloak is not on EC2)"
  type        = string
  default     = ""
}

variable "keycloak_secret_name" {
  type    = string
  default = "demo/keycloak-credentials"
}

variable "keycloak_http_port" {
  type    = number
  default = 8080
}

variable "realm_name" {
  type    = string
  default = "nifi"
}

# ---------- NiFi ----------
variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "nifi_version" {
  type    = string
  default = "2.4.0"
}

variable "artifact_bucket" {
  type    = string
  default = ""
}

variable "artifact_key" {
  type    = string
  default = ""
}

variable "download_url" {
  type    = string
  default = ""
}

variable "https_port" {
  type    = number
  default = 8443
}

variable "proxy_hosts" {
  type    = list(string)
  default = ["localhost:8443"]
}
