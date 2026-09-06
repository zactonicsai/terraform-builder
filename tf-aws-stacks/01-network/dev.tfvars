region       = "us-east-1"
project_name = "demo"

vpc_cidr         = "10.0.0.0/16"
azs              = ["us-east-1a", "us-east-1b"]
app_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
db_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]


interface_endpoints = ["secretsmanager", "ssm", "ssmmessages", "ec2messages"]
