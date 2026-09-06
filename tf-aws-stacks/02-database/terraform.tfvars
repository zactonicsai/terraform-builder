region       = "us-east-1"
project_name = "demo"

db_engine_version    = "17"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "appdb"
db_username          = "rcadmin"
db_password          = "changeme"   # stored in Secrets Manager; change for anything real
db_port              = 5432
app_port             = 80
