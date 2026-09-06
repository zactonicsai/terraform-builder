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
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

# ----- NiFi software -----
variable "nifi_version" {
  type    = string
  default = "2.4.0"
}

variable "artifact_bucket" {
  type    = string
  default = ""
}

variable "artifact_key" {
  description = "S3 key of nifi-<version>-bin.zip. Empty = download_url."
  type        = string
  default     = ""
}

variable "download_url" {
  type    = string
  default = ""
}

# ----- Keycloak (existing) -----
variable "keycloak_secret_arn" {
  description = "Secret created by the keycloak module (client secret, admin email, ...)"
  type        = string
}

variable "keycloak_private_ip" {
  description = "Private IP or DNS of the Keycloak server, used by NiFi's backend"
  type        = string
}

variable "keycloak_http_port" {
  type    = number
  default = 8080
}

variable "realm_name" {
  type    = string
  default = "nifi"
}

# ----- NiFi settings -----
variable "https_port" {
  type    = number
  default = 8443
}

variable "proxy_hosts" {
  description = "Host:port values browsers use to reach NiFi (nifi.web.proxy.host)"
  type        = list(string)
  default     = ["localhost:8443"]
}
