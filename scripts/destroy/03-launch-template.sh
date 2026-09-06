#!/bin/bash
# Step 3: delete launch templates.
set -euo pipefail
source "$(dirname "$0")/../common.sh"

LTS=$(aws ec2 describe-launch-templates --region "$REGION" --filters "$TAG_FILTER" \
  --query 'LaunchTemplates[].LaunchTemplateId' --output text)

if [[ -z "$LTS" ]]; then echo "No launch templates found for Project=$PROJECT"; exit 0; fi
echo "Launch templates to delete: $LTS"
confirm "Delete these launch templates?" || exit 1

for lt in $LTS; do
  aws ec2 delete-launch-template --region "$REGION" --launch-template-id "$lt" \
    --query 'LaunchTemplate.LaunchTemplateName' --output text
done
echo "Launch templates deleted."
