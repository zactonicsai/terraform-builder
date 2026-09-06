#!/bin/bash
# Shared settings for the view / destroy scripts.
# Override with env vars:  PROJECT=my-app REGION=us-west-2 ./view-resources.sh
export PROJECT="${PROJECT:-hello-web}"
export REGION="${REGION:-us-east-1}"
export AWS_PAGER=""
export TAG_FILTER="Name=tag:Project,Values=${PROJECT}"

# Prompt unless FORCE=1 is set
confirm() {
  [[ "${FORCE:-0}" == "1" ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

header() { printf '\n==== %s ====\n' "$1"; }
