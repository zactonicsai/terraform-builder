variable "name" {
  description = "Prefix for names/tags"
  type        = string
}

variable "identifier" {
  description = "Identifier for the NEW database instance"
  type        = string
}

# --- Which snapshot? Give one of these two. ---
variable "snapshot_identifier" {
  description = "Exact snapshot to restore. Leave empty to auto-pick the newest snapshot of source_db_identifier."
  type        = string
  default     = ""
}

variable "source_db_identifier" {
  description = "Existing DB whose newest snapshot should be used (only when snapshot_identifier is empty)"
  type        = string
  default     = ""
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security groups to attach to the restored database"
  type        = list(string)
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "password_length" {
  type    = number
  default = 20
}

variable "secret_name" {
  description = "Secrets Manager name for the NEW password. Empty = <name>/<identifier>-credentials"
  type        = string
  default     = ""
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}
