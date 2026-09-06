#!/bin/bash
# Example custom first-boot script. Enable with user_data_file in terraform.tfvars.
# Available placeholders: secret_arn, db_endpoint, db_port, db_name, region, app_port
dnf install -y python3
mkdir -p /opt/site
cat > /opt/site/index.html <<HTML
<h1>Custom page</h1>
<p>Database: ${db_endpoint}:${db_port}/${db_name}</p>
HTML
cd /opt/site && nohup python3 -m http.server ${app_port} >/dev/null 2>&1 &
