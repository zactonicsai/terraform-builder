variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Who may reach Keycloak on its HTTP port"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "extra_security_group_ids" {
  description = "Existing SGs to also attach, e.g. the app SG that RDS trusts"
  type        = list(string)
  default     = []
}

# ----- existing database -----
variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_secret_arn" {
  description = "Secret with username/password of the RDS master user"
  type        = string
}

variable "db_admin_database" {
  description = "An existing database to connect to when creating the keycloak database"
  type        = string
  default     = "postgres"
}

variable "keycloak_db_name" {
  description = "Database Keycloak will create/use inside the RDS instance"
  type        = string
  default     = "keycloak"
}

# ----- Keycloak software -----
variable "keycloak_version" {
  type    = string
  default = "26.3.2"
}

variable "artifact_bucket" {
  description = "S3 bucket holding the Keycloak tarball (needed when the VPC has no internet)"
  type        = string
  default     = ""
}

variable "artifact_key" {
  description = "S3 key of keycloak-<version>.tar.gz. Empty = download_url is used instead."
  type        = string
  default     = ""
}

variable "download_url" {
  description = "Used only when artifact_key is empty (requires internet from the VPC)"
  type        = string
  default     = ""
}

# ----- Keycloak settings -----
variable "http_port" {
  type    = number
  default = 8080
}

variable "public_url" {
  description = "URL browsers will use to reach Keycloak. localhost = via Session Manager port-forward."
  type        = string
  default     = "http://localhost:8080"
}

variable "admin_username" {
  type    = string
  default = "admin"
}

# ----- the sample realm -----
variable "realm_name" {
  type    = string
  default = "nifi"
}

variable "nifi_client_id" {
  type    = string
  default = "nifi"
}

variable "nifi_redirect_uris" {
  description = "Allowed OIDC redirect URIs for the NiFi client"
  type        = list(string)
  default     = ["https://localhost:8443/*", "https://*:8443/*"]
}

variable "nifi_user" {
  type    = string
  default = "nifiadmin"
}

variable "nifi_user_email" {
  description = "NiFi identifies users by email; this becomes NiFi's Initial Admin Identity"
  type        = string
  default     = "nifiadmin@example.com"
}

variable "secret_name" {
  description = "Secrets Manager name for the Keycloak admin + NiFi client credentials"
  type        = string
  default     = ""
}
