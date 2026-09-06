output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_port" {
  value = module.rds.port
}

output "secret_arn" {
  value = module.rds.secret_arn
}

output "secret_name" {
  value = module.rds.secret_name
}

output "app_sg_id" {
  description = "Attach this to the app servers (Stack 3 looks it up by name)"
  value       = module.rds.app_sg_id
}
