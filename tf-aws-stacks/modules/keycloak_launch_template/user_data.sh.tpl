#!/bin/bash
# First boot: install Keycloak, point it at the existing RDS PostgreSQL,
# create the "${realm_name}" realm with a NiFi OIDC client and a test user.
set -e
exec > /var/log/keycloak-setup.log 2>&1

dnf install -y java-21-amazon-corretto-headless
dnf install -y postgresql17 || dnf install -y postgresql16

# ---- 1. Get the Keycloak tarball (S3 when there is no internet) ----
if [ -n "${artifact_key}" ]; then
  aws s3 cp "s3://${artifact_bucket}/${artifact_key}" /tmp/keycloak.tar.gz --region ${region}
else
  curl -fsSL -o /tmp/keycloak.tar.gz "${download_url}"
fi
mkdir -p /opt/keycloak
tar xzf /tmp/keycloak.tar.gz -C /opt/keycloak --strip-components=1

# ---- 2. Read secrets ----
getsecret() { aws secretsmanager get-secret-value --secret-id "$1" --region ${region} --query SecretString --output text; }
field()     { echo "$1" | python3 -c "import sys,json;print(json.load(sys.stdin)['$2'])"; }
DBS=$(getsecret "${db_secret_arn}")
KCS=$(getsecret "${kc_secret_arn}")
DB_USER=$(field "$DBS" username)
DB_PASS=$(field "$DBS" password)
ADMIN_USER=$(field "$KCS" admin_username)
ADMIN_PASS=$(field "$KCS" admin_password)
NIFI_SECRET=$(field "$KCS" nifi_client_secret)
NIFI_USER=$(field "$KCS" nifi_user)
NIFI_PASS=$(field "$KCS" nifi_user_password)
NIFI_EMAIL=$(field "$KCS" nifi_user_email)

# ---- 3. Create Keycloak's own database inside the existing RDS ----
export PGPASSWORD="$DB_PASS"
EXISTS=$(psql -h ${db_endpoint} -p ${db_port} -U "$DB_USER" -d ${db_admin_database} -tAc "SELECT 1 FROM pg_database WHERE datname='${keycloak_db_name}'")
if [ "$EXISTS" != "1" ]; then
  psql -h ${db_endpoint} -p ${db_port} -U "$DB_USER" -d ${db_admin_database} -c "CREATE DATABASE ${keycloak_db_name}"
fi
unset PGPASSWORD

# ---- 4. Realm file: imported automatically on first start ----
mkdir -p /opt/keycloak/data/import
cat > /opt/keycloak/data/import/${realm_name}-realm.json <<JSON
{
  "realm": "${realm_name}",
  "enabled": true,
  "sslRequired": "none",
  "clients": [
    {
      "clientId": "${nifi_client_id}",
      "name": "Apache NiFi",
      "enabled": true,
      "protocol": "openid-connect",
      "publicClient": false,
      "clientAuthenticatorType": "client-secret",
      "secret": "$NIFI_SECRET",
      "standardFlowEnabled": true,
      "directAccessGrantsEnabled": false,
      "redirectUris": ${redirect_uris_json},
      "webOrigins": ["+"],
      "defaultClientScopes": ["openid", "profile", "email", "roles"]
    }
  ],
  "users": [
    {
      "username": "$NIFI_USER",
      "enabled": true,
      "email": "$NIFI_EMAIL",
      "emailVerified": true,
      "firstName": "NiFi",
      "lastName": "Admin",
      "credentials": [ { "type": "password", "value": "$NIFI_PASS", "temporary": false } ]
    }
  ]
}
JSON

# ---- 5. Keycloak configuration ----
cat > /opt/keycloak/keycloak.env <<ENV
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://${db_endpoint}:${db_port}/${keycloak_db_name}
KC_DB_USERNAME=$DB_USER
KC_DB_PASSWORD=$DB_PASS
KC_BOOTSTRAP_ADMIN_USERNAME=$ADMIN_USER
KC_BOOTSTRAP_ADMIN_PASSWORD=$ADMIN_PASS
KC_HTTP_ENABLED=true
KC_HTTP_PORT=${http_port}
KC_HOSTNAME=${public_url}
KC_HOSTNAME_STRICT=false
KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true
KC_HEALTH_ENABLED=true
ENV
chmod 600 /opt/keycloak/keycloak.env

useradd -r -s /sbin/nologin keycloak || true
chown -R keycloak:keycloak /opt/keycloak

# ---- 6. Run as a service ----
cat > /etc/systemd/system/keycloak.service <<UNIT
[Unit]
Description=Keycloak
After=network-online.target

[Service]
User=keycloak
EnvironmentFile=/opt/keycloak/keycloak.env
ExecStart=/opt/keycloak/bin/kc.sh start --import-realm
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now keycloak
echo "Keycloak setup finished."
