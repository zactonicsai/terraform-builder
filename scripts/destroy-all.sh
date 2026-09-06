#!/bin/bash
# Destroy every resource from the example, in dependency order.
#   ./destroy-all.sh            -> prompts once, then runs all steps
#   FORCE=1 ./destroy-all.sh    -> no prompts
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/common.sh"

echo "This will destroy ALL resources tagged Project=$PROJECT in $REGION:"
"$DIR/view-resources.sh"
echo
confirm "Proceed with full teardown?" || { echo "Aborted."; exit 1; }

export FORCE=1
"$DIR/destroy/01-instances.sh"
"$DIR/destroy/02-eips.sh"
"$DIR/destroy/03-launch-template.sh"
"$DIR/destroy/04-security-group.sh"

echo
echo "Teardown complete. If you used Terraform to create these, also run:"
echo "  cd examples/simple-website && terraform state list   # then 'terraform state rm' or delete terraform.tfstate"
