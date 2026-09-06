# Stack 3: launch template + ASG + one EC2, all running the CRUD website.
# Apply AFTER 02-database.

module "launch_template" {
  source = "../modules/launch_template"

  name              = var.project_name
  region            = var.region
  instance_type     = var.instance_type
  security_group_id = data.aws_security_group.app.id
  secret_arn        = data.aws_secretsmanager_secret.db.arn
  db_endpoint       = data.aws_db_instance.this.address
  db_port           = data.aws_db_instance.this.port
  db_name           = data.aws_db_instance.this.db_name
  app_port          = var.app_port
  user_data         = var.user_data
  user_data_file    = var.user_data_file
}

module "asg" {
  source = "../modules/asg"

  name               = var.project_name
  subnet_ids         = data.aws_subnets.app.ids
  launch_template_id = module.launch_template.launch_template_id
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
}

module "ec2" {
  source = "../modules/ec2"

  name               = "${var.project_name}-app"
  subnet_id          = data.aws_subnets.app.ids[0]
  launch_template_id = module.launch_template.launch_template_id
}
