#!/bin/bash
# Step 4: delete the security group (must run after instances are fully terminated).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

SGS=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=${PROJECT}-web" \
  --query 'SecurityGroups[].GroupId' --output text)

if [[ -z "$SGS" ]]; then echo "No security group found for Project=$PROJECT"; exit 0; fi
echo "Security groups to delete: $SGS"
confirm "Delete these security groups?" || exit 1

for sg in $SGS; do
  # Retry: ENIs can linger briefly after instance termination
  for i in {1..10}; do
    if aws ec2 delete-security-group --region "$REGION" --group-id "$sg" 2>/dev/null; then
      echo "Deleted $sg"; break
    fi
    echo "  $sg still in use, retrying in 10s ($i/10)..."; sleep 10
  done
done
