output "id" {
  description = "Launch template ID"
  value       = aws_launch_template.this.id
}

output "arn" {
  description = "Launch template ARN"
  value       = aws_launch_template.this.arn
}

output "name" {
  description = "Launch template name"
  value       = aws_launch_template.this.name
}

output "latest_version" {
  description = "Latest launch template version number"
  value       = aws_launch_template.this.latest_version
}

output "default_version" {
  description = "Default launch template version number"
  value       = aws_launch_template.this.default_version
}
