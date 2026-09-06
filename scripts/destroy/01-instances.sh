#!/bin/bash
# Step 1: terminate EC2 instances (root volumes are delete-on-termination).
set -euo pipefail
source "$(dirname "$0")/../common.sh"

IDS=$(aws ec2 describe-instances --region "$REGION" \
  --filters "$TAG_FILTER" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].InstanceId' --output text)

if [[ -z "$IDS" ]]; then echo "No instances found for Project=$PROJECT"; exit 0; fi
echo "Instances to terminate: $IDS"
confirm "Terminate these instances?" || exit 1

# shellcheck disable=SC2086
aws ec2 terminate-instances --region "$REGION" --instance-ids $IDS --output table
echo "Waiting for termination..."
# shellcheck disable=SC2086
aws ec2 wait instance-terminated --region "$REGION" --instance-ids $IDS
echo "Instances terminated."
