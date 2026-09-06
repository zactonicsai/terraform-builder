output "nifi_instance_id" {
  value = module.nifi_ec2.instance_id
}

output "nifi_private_ip" {
  value = module.nifi_ec2.private_ip
}

output "keycloak_ip_used" {
  value = local.keycloak_ip
}

output "nifi_url_after_port_forward" {
  value = "https://localhost:${var.https_port}/nifi"
}

output "port_forward_command" {
  value = "aws ssm start-session --region ${var.region} --target ${module.nifi_ec2.instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.https_port}\"],\"localPortNumber\":[\"${var.https_port}\"]}'"
}
