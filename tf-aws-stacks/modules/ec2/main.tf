# One standalone server built from the launch template.
# The Name tag is exactly var.name so other stacks can look it up.
resource "aws_instance" "this" {
  subnet_id = var.subnet_id

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tags = { Name = var.name }
}
