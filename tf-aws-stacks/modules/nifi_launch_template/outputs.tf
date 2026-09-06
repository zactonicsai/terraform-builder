output "launch_template_id" {
  value = aws_launch_template.nifi.id
}

output "security_group_id" {
  value = aws_security_group.nifi.id
}
