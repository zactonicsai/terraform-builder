output "launch_template_id" {
  value = aws_launch_template.this.id
}

output "iam_role_name" {
  value = aws_iam_role.instance.name
}
