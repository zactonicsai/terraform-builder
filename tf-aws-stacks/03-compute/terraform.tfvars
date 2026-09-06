region       = "us-east-1"
project_name = "demo"

instance_type = "t3.micro"
app_port      = 80

asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# First-boot script overrides. Leave both empty for the built-in CRUD website.
# user_data_file = "custom_user_data.sh.tpl"
# user_data = <<-EOT
#   #!/bin/bash
#   echo hello > /tmp/hello.txt
# EOT
user_data      = ""
user_data_file = ""
