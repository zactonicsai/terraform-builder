variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "demo"
}

# ---------- EXISTING resources, found by name/tag ----------
variable "vpc_name" {
  description = "Name tag of the existing VPC"
  type        = string
  default     = "demo-vpc"
}

variable "subnet_tier" {
  description = "Tier tag of the subnets to place Keycloak in"
  type        = string
  default     = "app"
}

variable "db_identifier" {
  description = "Existing RDS instance identifier"
  type        = string
  default     = "demo-db"
}

variable "db_secret_name" {
  description = "Existing secret holding the RDS master username/password"
  type        = string
  default     = "demo/db-credentials"
}

variable "db_client_security_group_name" {
  description = "Existing SG that the RDS security group trusts; Keycloak wears it too"
  type        = string
  default     = "demo-app-sg"
}

variable "db_admin_database" {
  description = "Existing database to connect to when creating the keycloak database"
  type        = string
  default     = "appdb"
}

# ---------- Keycloak ----------
variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "keycloak_version" {
  type    = string
  default = "26.3.2"
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

variable "public_url" {
  type    = string
  default = "http://localhost:8080"
}

variable "realm_name" {
  type    = string
  default = "nifi"
}

variable "nifi_redirect_uris" {
  type    = list(string)
  default = ["https://localhost:8443/*", "https://*:8443/*"]
}

variable "nifi_user_email" {
  type    = string
  default = "nifiadmin@example.com"
}
