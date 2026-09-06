output "endpoint" {
  value = aws_db_instance.restored.address
}

output "port" {
  value = aws_db_instance.restored.port
}

output "username" {
  value = aws_db_instance.restored.username
}

output "db_name" {
  value = aws_db_instance.restored.db_name
}

output "snapshot_used" {
  value = local.snapshot_id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.db.name
}
