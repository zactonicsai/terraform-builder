region       = "us-east-1"
project_name = "demo"

restored_identifier  = "demo-db-restored"
source_db_identifier = "demo-db"   # newest snapshot of this DB is used...
snapshot_identifier  = ""          # ...unless you name an exact snapshot here
instance_class       = "db.t3.micro"
password_length      = 20
