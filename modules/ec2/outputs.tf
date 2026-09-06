output "instance_ids" {
  description = "Instance IDs"
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IPs"
  value       = aws_instance.this[*].private_ip
}

output "public_ips" {
  description = "Public IPs (EIP if created, otherwise the auto-assigned IP)"
  value       = var.create_eip ? aws_eip.this[*].public_ip : aws_instance.this[*].public_ip
}

output "public_dns" {
  description = "Public DNS names"
  value       = aws_instance.this[*].public_dns
}
