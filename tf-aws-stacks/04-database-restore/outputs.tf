output "restored_endpoint" {
  value = module.restored_db.endpoint
}

output "restored_username" {
  value = module.restored_db.username
}

output "snapshot_used" {
  value = module.restored_db.snapshot_used
}

output "new_secret_name" {
  description = "aws secretsmanager get-secret-value --secret-id <this> --query SecretString --output text"
  value       = module.restored_db.secret_name
}
