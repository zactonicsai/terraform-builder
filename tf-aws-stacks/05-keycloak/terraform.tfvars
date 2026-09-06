region       = "us-east-1"
project_name = "demo"

# ---- existing resources (from stacks 1 and 2, or anything with the same names) ----
vpc_name                      = "demo-vpc"
subnet_tier                   = "app"
db_identifier                 = "demo-db"
db_secret_name                = "demo/db-credentials"
db_client_security_group_name = "demo-app-sg"
db_admin_database             = "appdb"

# ---- Keycloak ----
instance_type    = "t3.small"
keycloak_version = "26.3.2"

# No internet in the VPC? Upload the tarball first:  ./scripts/upload-artifacts.sh <bucket>
artifact_bucket = ""                          # e.g. "my-artifacts-bucket"
artifact_key    = ""                          # e.g. "keycloak-26.3.2.tar.gz"
download_url    = ""                          # only used if artifact_key is empty

public_url         = "http://localhost:8080"  # what YOUR browser uses (port-forward)
realm_name         = "nifi"
nifi_redirect_uris = ["https://localhost:8443/*", "https://*:8443/*"]
nifi_user_email    = "nifiadmin@example.com"
