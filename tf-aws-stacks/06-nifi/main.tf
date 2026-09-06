# Stack 6: Apache NiFi with OIDC login through the existing Keycloak.
module "nifi_lt" {
  source = "../modules/nifi_launch_template"

  name          = var.project_name
  region        = var.region
  vpc_id        = data.aws_vpc.this.id
  vpc_cidr      = data.aws_vpc.this.cidr_block
  instance_type = var.instance_type

  nifi_version    = var.nifi_version
  artifact_bucket = var.artifact_bucket
  artifact_key    = var.artifact_key
  download_url    = var.download_url

  keycloak_secret_arn = data.aws_secretsmanager_secret.keycloak.arn
  keycloak_private_ip = local.keycloak_ip
  keycloak_http_port  = var.keycloak_http_port
  realm_name          = var.realm_name

  https_port  = var.https_port
  proxy_hosts = var.proxy_hosts
}

module "nifi_ec2" {
  source = "../modules/ec2"

  name               = "${var.project_name}-nifi"
  subnet_id          = data.aws_subnets.app.ids[0]
  launch_template_id = module.nifi_lt.launch_template_id
}
