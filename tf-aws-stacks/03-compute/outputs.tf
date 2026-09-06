output "ec2_instance_id" {
  description = "Use with: aws ssm start-session --target <id>"
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  value = module.ec2.private_ip
}

output "asg_name" {
  value = module.asg.asg_name
}

output "port_forward_command" {
  description = "Run this, then open http://localhost:8080"
  value       = "aws ssm start-session --region ${var.region} --target ${module.ec2.instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.app_port}\"],\"localPortNumber\":[\"8080\"]}'"
}
