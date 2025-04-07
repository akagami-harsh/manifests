#!/bin/bash
set -e

# Get absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running kustomize build for Kubeflow overlay..."
echo "Working directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR"

kustomize build \
  --enable-helm \
  --helm-command helm \
  --load-restrictor LoadRestrictionsNone \
  base
