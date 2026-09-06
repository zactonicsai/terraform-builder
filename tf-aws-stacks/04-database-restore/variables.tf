variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "demo"
}

variable "restored_identifier" {
  description = "Name of the new database"
  type        = string
  default     = "demo-db-restored"
}

variable "snapshot_identifier" {
  description = "Exact snapshot to restore. Empty = newest snapshot of source_db_identifier."
  type        = string
  default     = ""
}

variable "source_db_identifier" {
  description = "Existing DB to take the newest snapshot from"
  type        = string
  default     = "demo-db"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "password_length" {
  type    = number
  default = 20
}
