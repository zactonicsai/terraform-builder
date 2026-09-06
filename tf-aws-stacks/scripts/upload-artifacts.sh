#!/usr/bin/env bash
# upload-artifacts.sh - run from a machine WITH internet. Downloads Keycloak and
# NiFi and uploads them to S3 so servers in the no-internet VPC can fetch them
# through the S3 gateway endpoint.
# Usage: ./scripts/upload-artifacts.sh <bucket> [keycloak_version] [nifi_version] [region]
set -euo pipefail
B="${1:?bucket name required}"; KC="${2:-26.3.2}"; NF="${3:-2.4.0}"; R="${4:-us-east-1}"

aws s3api head-bucket --bucket "$B" 2>/dev/null || aws s3 mb "s3://$B" --region "$R"

curl -fL -o "keycloak-$KC.tar.gz" "https://github.com/keycloak/keycloak/releases/download/$KC/keycloak-$KC.tar.gz"
curl -fL -o "nifi-$NF-bin.zip"    "https://archive.apache.org/dist/nifi/$NF/nifi-$NF-bin.zip"

aws s3 cp "keycloak-$KC.tar.gz" "s3://$B/keycloak-$KC.tar.gz"
aws s3 cp "nifi-$NF-bin.zip"    "s3://$B/nifi-$NF-bin.zip"

cat <<MSG

Done. Put these in your tfvars:

05-keycloak/terraform.tfvars:
  artifact_bucket = "$B"
  artifact_key    = "keycloak-$KC.tar.gz"

06-nifi/terraform.tfvars:
  artifact_bucket = "$B"
  artifact_key    = "nifi-$NF-bin.zip"
MSG
