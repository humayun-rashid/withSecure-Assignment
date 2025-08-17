#!/usr/bin/env bash
set -e

BASE_URL="http://localhost:8080"

echo "🔍 Testing ListService API at $BASE_URL"

# Health check
echo -n "➡️  /health ... "
if curl -s -f "$BASE_URL/health" >/dev/null; then
  echo "✅ OK"
else
  echo "❌ FAILED"
  exit 1
fi

# Head GET
echo -n "➡️  /v1/lists/head (GET) ... "
RESPONSE=$(curl -s "$BASE_URL/v1/lists/head?list=foo,bar,baz&count=2")
EXPECTED='{"result":["foo","bar"]}'
if [ "$RESPONSE" = "$EXPECTED" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $EXPECTED, got $RESPONSE"
  exit 1
fi

# Tail GET
echo -n "➡️  /v1/lists/tail (GET) ... "
RESPONSE=$(curl -s "$BASE_URL/v1/lists/tail?list=foo,bar,baz&count=2")
EXPECTED='{"result":["bar","baz"]}'
if [ "$RESPONSE" = "$EXPECTED" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $EXPECTED, got $RESPONSE"
  exit 1
fi

echo "🎉 All tests passed"
