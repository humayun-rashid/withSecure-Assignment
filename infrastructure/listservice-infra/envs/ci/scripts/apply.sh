#!/usr/bin/env bash
set -euo pipefail

terraform init -reconfigure -backend-config=backend.hcl
terraform apply -auto-approve tf.plan
