#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://localhost:8080"   # Change port if your app runs elsewhere

echo "🔍 Testing ListService API at $BASE_URL"

# Health check
echo -n "➡️  /health ... "
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$code" = "200" ]; then
  echo "✅ OK"
else
  echo "❌ Failed (code=$code)"
  exit 1
fi

# GET /head
echo -n "➡️  /v1/lists/head (GET) ... "
resp=$(curl -s "$BASE_URL/v1/lists/head?list=foo,bar,baz&count=2")
expected='{"result":["foo","bar"]}'
if [ "$resp" = "$expected" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $expected, got $resp"
  exit 1
fi

# GET /tail
echo -n "➡️  /v1/lists/tail (GET) ... "
resp=$(curl -s "$BASE_URL/v1/lists/tail?list=foo,bar,baz&count=2")
expected='{"result":["bar","baz"]}'
if [ "$resp" = "$expected" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $expected, got $resp"
  exit 1
fi

# POST /head
echo -n "➡️  /v1/lists/head (POST) ... "
resp=$(curl -s -X POST "$BASE_URL/v1/lists/head" \
  -H "Content-Type: application/json" \
  -d '{"list":["one","two","three"],"count":2}')
expected='{"result":["one","two"]}'
if [ "$resp" = "$expected" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $expected, got $resp"
  exit 1
fi

# POST /tail
echo -n "➡️  /v1/lists/tail (POST) ... "
resp=$(curl -s -X POST "$BASE_URL/v1/lists/tail" \
  -H "Content-Type: application/json" \
  -d '{"list":["one","two","three"],"count":1}')
expected='{"result":["two","three"]}'
if [ "$resp" = "$expected" ]; then
  echo "✅ Passed"
else
  echo "❌ Expected $expected, got $resp"
  exit 1
fi

# Negative test: count too large
echo -n "➡️  Negative test (count too large) ... "
resp=$(curl -s -w " HTTP_CODE:%{http_code}" \
  "$BASE_URL/v1/lists/head?list=a,b&count=5")
body=$(echo "$resp" | sed 's/ HTTP_CODE:.*//')
code=$(echo "$resp" | sed 's/.*HTTP_CODE://')
if [ "$code" = "400" ] && echo "$body" | grep -q "count"; then
  echo "✅ Passed"
else
  echo "❌ Expected HTTP 400 error about 'count', got code=$code body=$body"
  exit 1
fi

echo "🎉 All tests passed!"
