# Stack 5: Keycloak on an existing VPC + existing RDS. Independent of stacks 3/4.
module "keycloak_lt" {
  source = "../modules/keycloak_launch_template"

  name                     = var.project_name
  region                   = var.region
  vpc_id                   = data.aws_vpc.this.id
  vpc_cidr                 = data.aws_vpc.this.cidr_block
  instance_type            = var.instance_type
  extra_security_group_ids = [data.aws_security_group.db_client.id]

  db_endpoint       = data.aws_db_instance.this.address
  db_port           = data.aws_db_instance.this.port
  db_secret_arn     = data.aws_secretsmanager_secret.db.arn
  db_admin_database = var.db_admin_database

  keycloak_version   = var.keycloak_version
  artifact_bucket    = var.artifact_bucket
  artifact_key       = var.artifact_key
  download_url       = var.download_url
  public_url         = var.public_url
  realm_name         = var.realm_name
  nifi_redirect_uris = var.nifi_redirect_uris
  nifi_user_email    = var.nifi_user_email
}

module "keycloak_ec2" {
  source = "../modules/ec2"

  name               = "${var.project_name}-keycloak"
  subnet_id          = data.aws_subnets.app.ids[0]
  launch_template_id = module.keycloak_lt.launch_template_id
}
