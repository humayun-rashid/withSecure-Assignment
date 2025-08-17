#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "🔍 Testing ListService API at $BASE_URL"

fail() {
  echo "❌ $1"
  exit 1
}

# /health
echo -n "➡️  /health ... "
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
[ "$code" = "200" ] || fail "Expected 200, got $code"
echo "✅ OK"

# /head (GET)
echo -n "➡️  /v1/lists/head (GET) ... "
resp=$(curl -s "$BASE_URL/v1/lists/head?list=foo,bar,baz&count=2")
[ "$resp" = '{"result":["foo","bar"]}' ] || fail "Expected {\"result\":[\"foo\",\"bar\"]}, got $resp"
echo "✅ Passed"

# /tail (GET)
echo -n "➡️  /v1/lists/tail (GET) ... "
resp=$(curl -s "$BASE_URL/v1/lists/tail?list=foo,bar,baz&count=2")
[ "$resp" = '{"result":["bar","baz"]}' ] || fail "Expected {\"result\":[\"bar\",\"baz\"]}, got $resp"
echo "✅ Passed"

# /head (POST)
echo -n "➡️  /v1/lists/head (POST) ... "
resp=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"list":["one","two","three"],"count":2}' \
  "$BASE_URL/v1/lists/head")
[ "$resp" = '{"result":["one","two"]}' ] || fail "Expected {\"result\":[\"one\",\"two\"]}, got $resp"
echo "✅ Passed"

# /tail (POST)
echo -n "➡️  /v1/lists/tail (POST) ... "
resp=$(curl -s -X POST -H "Content-Type: application/json" \
  -d '{"list":["one","two","three"],"count":2}' \
  "$BASE_URL/v1/lists/tail")
[ "$resp" = '{"result":["two","three"]}' ] || fail "Expected {\"result\":[\"two\",\"three\"]}, got $resp"
echo "✅ Passed"

# Negative test: count too large
echo -n "➡️  Negative test (count too large) ... "
resp=$(curl -s -w " HTTP_CODE:%{http_code}" "$BASE_URL/v1/lists/head?list=a,b&count=5")
body=$(echo "$resp" | sed 's/ HTTP_CODE:.*//')
code=$(echo "$resp" | sed 's/.*HTTP_CODE://')
if [ "$code" != "400" ]; then
  fail "Expected HTTP 400, got $code"
fi
echo "✅ Passed (got 400 with error: $body)"

echo "🎉 All smoke tests passed!"
