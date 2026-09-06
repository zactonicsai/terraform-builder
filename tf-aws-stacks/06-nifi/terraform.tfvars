region       = "us-east-1"
project_name = "demo"

# ---- existing resources ----
vpc_name               = "demo-vpc"
subnet_tier            = "app"
keycloak_instance_name = "demo-keycloak"          # looked up by Name tag...
keycloak_private_ip    = ""                       # ...or give the IP/DNS directly
keycloak_secret_name   = "demo/keycloak-credentials"
keycloak_http_port     = 8080
realm_name             = "nifi"

# ---- NiFi ----
instance_type = "t3.medium"
nifi_version  = "2.4.0"

artifact_bucket = ""                              # e.g. "my-artifacts-bucket"
artifact_key    = ""                              # e.g. "nifi-2.4.0-bin.zip"
download_url    = ""

https_port  = 8443
proxy_hosts = ["localhost:8443"]                  # how YOUR browser reaches NiFi
