output "launch_template_id" {
  value = aws_launch_template.keycloak.id
}

output "security_group_id" {
  value = aws_security_group.keycloak.id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.keycloak.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.keycloak.name
}

output "realm_name" {
  value = var.realm_name
}
