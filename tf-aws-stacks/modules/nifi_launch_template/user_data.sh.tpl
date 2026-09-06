#!/bin/bash
# First boot: install Apache NiFi 2.x and log in through Keycloak (OIDC).
set -e
exec > /var/log/nifi-setup.log 2>&1

dnf install -y java-21-amazon-corretto-headless unzip

# ---- 1. Get NiFi (S3 when there is no internet) ----
if [ -n "${artifact_key}" ]; then
  aws s3 cp "s3://${artifact_bucket}/${artifact_key}" /tmp/nifi.zip --region ${region}
else
  curl -fsSL -o /tmp/nifi.zip "${download_url}"
fi
unzip -q /tmp/nifi.zip -d /opt
mv /opt/nifi-* /opt/nifi
CONF=/opt/nifi/conf

# ---- 2. Read the Keycloak secret ----
KCS=$(aws secretsmanager get-secret-value --secret-id "${keycloak_secret_arn}" --region ${region} --query SecretString --output text)
field() { echo "$KCS" | python3 -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }
CLIENT_ID=$(field nifi_client_id)
CLIENT_SECRET=$(field nifi_client_secret)
ADMIN_EMAIL=$(field nifi_user_email)

PRIVATE_IP=$(hostname -I | awk '{print $1}')
KS_PASS="${keystore_password}"

# ---- 3. Self-signed certificate (NiFi with OIDC must run HTTPS) ----
keytool -genkeypair -alias nifi -keyalg RSA -keysize 2048 -validity 825 \
  -keystore $CONF/keystore.p12 -storetype PKCS12 -storepass "$KS_PASS" -keypass "$KS_PASS" \
  -dname "CN=nifi" -ext "SAN=dns:localhost,ip:127.0.0.1,ip:$PRIVATE_IP"
keytool -exportcert -alias nifi -keystore $CONF/keystore.p12 -storepass "$KS_PASS" -rfc -file /tmp/nifi.crt
keytool -importcert -noprompt -alias nifi -file /tmp/nifi.crt \
  -keystore $CONF/truststore.p12 -storetype PKCS12 -storepass "$KS_PASS"

# ---- 4. nifi.properties ----
P=$CONF/nifi.properties
setp() { sed -i "s|^$1=.*|$1=$2|" "$P"; }

setp nifi.web.http.host ""
setp nifi.web.http.port ""
setp nifi.web.https.host 0.0.0.0
setp nifi.web.https.port ${https_port}
setp nifi.web.proxy.host "${proxy_hosts},$PRIVATE_IP:${https_port}"

setp nifi.security.keystore        $CONF/keystore.p12
setp nifi.security.keystoreType    PKCS12
setp nifi.security.keystorePasswd  "$KS_PASS"
setp nifi.security.keyPasswd       "$KS_PASS"
setp nifi.security.truststore      $CONF/truststore.p12
setp nifi.security.truststoreType  PKCS12
setp nifi.security.truststorePasswd "$KS_PASS"

# Turn OFF single-user login, turn ON the managed (file) authorizer + OIDC
setp nifi.security.user.login.identity.provider ""
setp nifi.security.user.authorizer managed-authorizer

setp nifi.security.user.oidc.discovery.url "http://${keycloak_host}:${keycloak_port}/realms/${realm_name}/.well-known/openid-configuration"
setp nifi.security.user.oidc.client.id "$CLIENT_ID"
setp nifi.security.user.oidc.client.secret "$CLIENT_SECRET"
setp nifi.security.user.oidc.claim.identifying.user email
setp nifi.security.user.oidc.additional.scopes email
setp nifi.security.user.oidc.preferred.jwsalgorithm RS256

# ---- 5. authorizers.xml: the Keycloak user becomes NiFi's first admin ----
A=$CONF/authorizers.xml
sed -i "s|<property name=\"Initial User Identity 1\"></property>|<property name=\"Initial User Identity 1\">$ADMIN_EMAIL</property>|" "$A"
sed -i "s|<property name=\"Initial Admin Identity\"></property>|<property name=\"Initial Admin Identity\">$ADMIN_EMAIL</property>|" "$A"

# ---- 6. Sensitive properties key (required before first start) ----
/opt/nifi/bin/nifi.sh set-sensitive-properties-key "${sensitive_props_key}"

useradd -r -s /sbin/nologin nifi || true
chown -R nifi:nifi /opt/nifi

# ---- 7. Run as a service ----
cat > /etc/systemd/system/nifi.service <<UNIT
[Unit]
Description=Apache NiFi
After=network-online.target

[Service]
User=nifi
Environment=JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
ExecStart=/opt/nifi/bin/nifi.sh run
Restart=always
RestartSec=10
LimitNOFILE=50000

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now nifi
echo "NiFi setup finished. Discovery URL: http://${keycloak_host}:${keycloak_port}/realms/${realm_name}/.well-known/openid-configuration"
