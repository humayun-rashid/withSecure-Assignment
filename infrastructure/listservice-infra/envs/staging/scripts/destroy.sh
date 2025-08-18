#!/usr/bin/env bash
set -euo pipefail

terraform init -reconfigure -backend-config=backend.hcl
terraform plan -destroy -out=tf.destroy -var-file=ci.tfvars
terraform apply -auto-approve tf.destroy
