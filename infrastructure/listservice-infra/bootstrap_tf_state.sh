#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Bootstrap / Reset Terraform remote state (S3 + DynamoDB lock)
#
# Features:
# - Creates S3 bucket with versioning, SSE-S3 encryption, public access block
# - Applies TLS-only bucket policy
# - Optionally PURGES prior objects (supports versioned buckets) by prefix or entire bucket
# - Creates DynamoDB table for locking; optionally drops & recreates it
# - Optionally writes backend.hcl for your env
#
# Examples:
#   ./bootstrap_tf_state.sh --profile sandbox --region eu-central-1 \
#     --backend-out envs/ci/backend.hcl \
#     --backend-key listservice/ci/terraform.tfstate
#
#   # Purge only the CI prefix (safe!)
#   ./bootstrap_tf_state.sh --profile sandbox --region eu-central-1 \
#     --backend-key listservice/ci/terraform.tfstate \
#     --purge-prefix listservice/ci/ --yes
#
#   # Nuke entire bucket contents + recreate DynamoDB table
#   ./bootstrap_tf_state.sh --profile sandbox --region eu-central-1 \
#     --purge-bucket --recreate-table --yes
#
# NOTE: Purging entire buckets is destructive; prefer purging just a prefix.
# ------------------------------------------------------------------------------

PROFILE=""
REGION="eu-central-1"
BUCKET_PREFIX="tf-state"
BUCKET=""
TABLE="tf-state-lock"
BACKEND_OUT=""
BACKEND_KEY=""
PURGE_BUCKET=false
PURGE_PREFIX=""
RECREATE_TABLE=false
ASSUME_YES=false

# ---------- Args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --bucket-prefix) BUCKET_PREFIX="$2"; shift 2 ;;
    --bucket) BUCKET="$2"; shift 2 ;;
    --table) TABLE="$2"; shift 2 ;;
    --backend-out) BACKEND_OUT="$2"; shift 2 ;;
    --backend-key) BACKEND_KEY="$2"; shift 2 ;;
    --purge-bucket) PURGE_BUCKET=true; shift 1 ;;
    --purge-prefix) PURGE_PREFIX="$2"; shift 2 ;;
    --recreate-table) RECREATE_TABLE=true; shift 1 ;;
    --yes|-y) ASSUME_YES=true; shift 1 ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

aws_cli() {
  if [[ -n "$PROFILE" ]]; then
    aws --profile "$PROFILE" --region "$REGION" "$@"
  else
    aws --region "$REGION" "$@"
  fi
}

confirm() {
  local msg="$1"
  if $ASSUME_YES; then return 0; fi
  read -r -p "$msg [y/N]: " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

echo ">>> Checking AWS identity..."
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
echo "Account: $ACCOUNT_ID | Region: $REGION | Profile: ${PROFILE:-<default>}"

if [[ -z "$BUCKET" ]]; then
  BUCKET="${BUCKET_PREFIX}-${ACCOUNT_ID}-${REGION}"
fi
echo "S3 bucket: $BUCKET"
echo "DynamoDB table: $TABLE"

# ---------- Create S3 bucket if missing ----------
echo ">>> Ensuring S3 bucket exists..."
if aws_cli s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket exists."
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws_cli s3api create-bucket --bucket "$BUCKET"
  else
    aws_cli s3api create-bucket \
      --bucket "$BUCKET" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "Created bucket $BUCKET"
fi

echo ">>> Enabling versioning..."
aws_cli s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo ">>> Enabling default encryption (SSE-S3)..."
aws_cli s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules":[{ "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm":"AES256" } }]
  }'

echo ">>> Blocking public access..."
aws_cli s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

echo ">>> Applying TLS-only bucket policy..."
TMPPOL="$(mktemp)"
cat > "$TMPPOL" <<POL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET",
        "arn:aws:s3:::$BUCKET/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    }
  ]
}
POL
aws_cli s3api put-bucket-policy --bucket "$BUCKET" --policy "file://$TMPPOL"
rm -f "$TMPPOL"

# ---------- Purge logic (versioned-safe) ----------
delete_versions_batch() {
  # Args: bucket prefix(optional)
  local bucket="$1"
  local prefix="${2-}"
  local token=""
  while : ; do
    if [[ -n "$prefix" ]]; then
      resp="$(aws_cli s3api list-object-versions --bucket "$bucket" --prefix "$prefix" --max-items 1000 ${token:+--starting-token "$token"} || true)"
    else
      resp="$(aws_cli s3api list-object-versions --bucket "$bucket" --max-items 1000 ${token:+--starting-token "$token"} || true)"
    fi

    # Build delete batch from Versions + DeleteMarkers
    keys="$(echo "$resp" | jq -r '
      [
        (.Versions // [])[] | {Key:.Key, VersionId:.VersionId}
      ] + [
        (.DeleteMarkers // [])[] | {Key:.Key, VersionId:.VersionId}
      ]')"

    count="$(echo "$keys" | jq 'length')"
    if [[ "$count" -eq 0 ]]; then
      break
    fi

    # Chunk into batches of 1000 (API limit)
    echo "$keys" | jq -c '. as $a | to_entries | group_by((.key/1000|floor)) | map(map(.value))[]' | while read -r batch; do
      aws_cli s3api delete-objects \
        --bucket "$bucket" \
        --delete "$(jq -c '{Objects: ., Quiet: true}' <<<"$batch")" >/dev/null
    done

    # Pagination token
    token="$(echo "$resp" | jq -r '."NextToken" // empty')"
    [[ -z "$token" ]] && break
  done
}

if $PURGE_BUCKET || [[ -n "$PURGE_PREFIX" ]] || [[ -n "$BACKEND_KEY" ]]; then
  # If user passed a backend key and no explicit prefix, derive the prefix folder from it
  if [[ -z "$PURGE_PREFIX" && -n "$BACKEND_KEY" ]]; then
    # e.g., listservice/ci/terraform.tfstate -> listservice/ci/
    PURGE_PREFIX="$(dirname "$BACKEND_KEY")/"
  fi

  if $PURGE_BUCKET; then
    if confirm "WARNING: Purge ALL objects (and versions) in s3://$BUCKET ?"; then
      echo ">>> Purging entire bucket (all keys, all versions)..."
      delete_versions_batch "$BUCKET"
    else
      echo "Skipped purging entire bucket."
    fi
  elif [[ -n "$PURGE_PREFIX" ]]; then
    if confirm "Purge objects under s3://$BUCKET/$PURGE_PREFIX ?"; then
      echo ">>> Purging prefix s3://$BUCKET/$PURGE_PREFIX ..."
      delete_versions_batch "$BUCKET" "$PURGE_PREFIX"
    else
      echo "Skipped purging prefix."
    fi
  fi
fi

# ---------- DynamoDB table ----------
echo ">>> Ensuring DynamoDB lock table..."
table_exists=false
if aws_cli dynamodb describe-table --table-name "$TABLE" >/dev/null 2>&1; then
  table_exists=true
fi

if $RECREATE_TABLE; then
  if $table_exists; then
    if confirm "Recreate DynamoDB table '$TABLE'? This will DELETE it."; then
      echo "Deleting table..."
      aws_cli dynamodb delete-table --table-name "$TABLE" >/dev/null
      echo "Waiting for table to be deleted..."
      aws_cli dynamodb wait table-not-exists --table-name "$TABLE"
      table_exists=false
    else
      echo "Skipping table recreation."
    fi
  fi
fi

if ! $table_exists; then
  echo "Creating table $TABLE (PAY_PER_REQUEST)..."
  aws_cli dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST >/dev/null
  echo "Waiting for table to become ACTIVE..."
  aws_cli dynamodb wait table-exists --table-name "$TABLE"
else
  echo "Table exists."
fi

# ---------- Optional backend.hcl ----------
if [[ -n "$BACKEND_OUT" ]]; then
  if [[ -z "$BACKEND_KEY" ]]; then
    echo "WARN: --backend-out provided without --backend-key. Using default key: listservice/ci/terraform.tfstate"
    BACKEND_KEY="listservice/ci/terraform.tfstate"
  fi
  echo ">>> Writing backend config to: $BACKEND_OUT"
  mkdir -p "$(dirname "$BACKEND_OUT")"
  cat > "$BACKEND_OUT" <<HCL
bucket         = "$BUCKET"
key            = "$BACKEND_KEY"
region         = "$REGION"
dynamodb_table = "$TABLE"
encrypt        = true
$( [[ -n "$PROFILE" ]] && echo "profile        = \"$PROFILE\"" )
HCL
fi

echo ">>> Done."
echo "S3 bucket : s3://$BUCKET"
echo "DynamoDB  : $TABLE"
[[ -n "$BACKEND_OUT" ]] && echo "Backend file: $BACKEND_OUT"
