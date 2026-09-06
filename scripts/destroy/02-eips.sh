#!/bin/bash
# Step 2: release Elastic IPs (only exist if create_eip = true).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

ALLOCS=$(aws ec2 describe-addresses --region "$REGION" --filters "$TAG_FILTER" \
  --query 'Addresses[].AllocationId' --output text)

if [[ -z "$ALLOCS" ]]; then echo "No Elastic IPs found for Project=$PROJECT"; exit 0; fi
echo "EIPs to release: $ALLOCS"
confirm "Release these Elastic IPs?" || exit 1

for a in $ALLOCS; do
  ASSOC=$(aws ec2 describe-addresses --region "$REGION" --allocation-ids "$a" \
    --query 'Addresses[0].AssociationId' --output text)
  if [[ "$ASSOC" != "None" && -n "$ASSOC" ]]; then
    aws ec2 disassociate-address --region "$REGION" --association-id "$ASSOC"
  fi
  aws ec2 release-address --region "$REGION" --allocation-id "$a"
  echo "Released $a"
done
