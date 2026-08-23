#!/usr/bin/env bash
set -euo pipefail

echo "Destroying Local Deployment Platform..."
cd terraform
terraform destroy -auto-approve
cd ..
echo "Platform teardown complete."
