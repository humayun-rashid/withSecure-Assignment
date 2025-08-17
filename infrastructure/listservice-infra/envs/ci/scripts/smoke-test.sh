#!/usr/bin/env bash
set -euo pipefail

# Always run relative to current directory (assume inside env folder, e.g., ci/)
ENV_DIR="$(pwd)"

# Get ALB DNS from Terraform outputs
ALB_DNS=$(terraform -chdir="$ENV_DIR" output -raw alb_dns)
BASE_URL="http://${ALB_DNS}"

echo "🔍 Smoke test against: $BASE_URL"

# --- Wait for health endpoint ---
echo "⏳ Waiting for service to become healthy..."
for i in {1..12}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/health" || true)
  if [ "$code" = "200" ]; then
    echo "✅ Service is healthy (HTTP 200)"
    break
  fi
  echo "Attempt $i: got $code, retrying in 10s..."
  sleep 10
done

if [ "$code" != "200" ]; then
  echo "❌ Service did not become healthy after 2 minutes"
  exit 1
fi

# --- Functional endpoint tests ---
echo "🚀 Testing API endpoints..."

echo "- GET /health"
curl -s "${BASE_URL}/health" | jq .

echo "- GET /v1/lists/head?list=a,b,c,d&count=2"
curl -s "${BASE_URL}/v1/lists/head?list=a,b,c,d&count=2" | jq .

echo "- POST /v1/lists/head"
curl -s -X POST "${BASE_URL}/v1/lists/head" \
  -H "Content-Type: application/json" \
  -d '{"list":["a","b","c","d"],"count":2}' | jq .

echo "- POST /v1/lists/tail"
curl -s -X POST "${BASE_URL}/v1/lists/tail" \
  -H "Content-Type: application/json" \
  -d '{"list":["a","b","c","d"],"count":2}' | jq .

echo "🎉 Smoke tests passed"
