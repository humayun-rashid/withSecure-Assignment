#!/usr/bin/env bash
set -euo pipefail

terraform init -reconfigure -backend-config=backend.hcl
terraform plan -out=tf.plan -var-file=ci.tfvars
