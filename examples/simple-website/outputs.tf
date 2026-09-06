output "website_url" {
  value = "http://${module.web.public_ips[0]}"
}

output "instance_id" {
  value = module.web.instance_ids[0]
}
