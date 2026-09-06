output "keycloak_instance_id" {
  value = module.keycloak_ec2.instance_id
}

output "keycloak_private_ip" {
  value = module.keycloak_ec2.private_ip
}

output "keycloak_secret_name" {
  value = module.keycloak_lt.secret_name
}

output "admin_console_after_port_forward" {
  value = "${var.public_url}/admin/ (realm: ${var.realm_name})"
}

output "port_forward_command" {
  value = "aws ssm start-session --region ${var.region} --target ${module.keycloak_ec2.instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"8080\"],\"localPortNumber\":[\"8080\"]}'"
}
