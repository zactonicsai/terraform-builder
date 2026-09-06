
module "web_lt" {
  source = "../../modules/launch_template"

  name          = "${var.project}-lt"
  description   = "Nginx hello page"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh", {
    site_title = "${var.project} on EC2"
  })

  block_device_mappings = [{
    device_name = "/dev/xvda"
    volume_size = 10
  }]

  instance_tags = {
    Project = var.project
    Role    = "web"
  }

  tags = { Project = var.project }
}

module "web" {
  source = "../../modules/ec2"

  name                    = "${var.project}-web"
  instance_count          = 1
  launch_template_id      = module.web_lt.id
  launch_template_version = module.web_lt.latest_version
  subnet_ids              = data.aws_subnets.default.ids

  tags = { Project = var.project }
}
