#!/usr/bin/env bash
set -euo pipefail

# Minimal, macOS-safe (Bash 3.x) OIDC reset + global role setup
PROFILE="sandbox"
REGION="eu-central-1"

OWNER="humayun-rashid"
REPO="withSecure-Assignment"
ENVIRONMENT="global"

ROLE_NAME="ListService-Global-Deploy"
STATE_PREFIX="listservice/global/"
LOCK_TABLE="tf-state-lock"
STATE_BUCKET=""
ASSUME_YES=false

# ----- flags -----
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --role-name) ROLE_NAME="$2"; shift 2 ;;
    --state-prefix) STATE_PREFIX="$2"; shift 2 ;;
    --state-bucket) STATE_BUCKET="$2"; shift 2 ;;
    --lock-table) LOCK_TABLE="$2"; shift 2 ;;
    --yes|-y) ASSUME_YES=true; shift 1 ;;
    -h|--help) echo "Usage: $0 [--profile p] [--region r] [--owner o] [--repo r] [--environment e] [--role-name n] [--state-prefix p] [--state-bucket b] [--lock-table t] [--yes]"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

aws_cli() { aws --profile "$PROFILE" --region "$REGION" "$@"; }

confirm() {
  $ASSUME_YES && return 0
  printf "%s [y/N]: " "$1"
  read -r ans
  case "$ans" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

echo ">>> Resolving AWS account…"
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
[ -z "$STATE_BUCKET" ] && STATE_BUCKET="tf-state-${ACCOUNT_ID}-${REGION}"
OIDC_ARN_PREFIX="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/"
OIDC_ARN="${OIDC_ARN_PREFIX}token.actions.githubusercontent.com"

echo "Account     : $ACCOUNT_ID"
echo "Region      : $REGION"
echo "Profile     : $PROFILE"
echo "Repo        : ${OWNER}/${REPO}"
echo "Trust scope : environment=${ENVIRONMENT}"
echo "Role name   : $ROLE_NAME"
echo "State S3    : s3://${STATE_BUCKET}/${STATE_PREFIX}"
echo "Lock table  : ${LOCK_TABLE}"
echo

# 1) Delete any existing GitHub OIDC providers for token.actions.githubusercontent.com
echo ">>> Checking existing OIDC providers…"
PROVIDERS="$(aws_cli iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text || true)"
FOUND=0
TO_DELETE=""
for ARN in $PROVIDERS; do
  URL="$(aws_cli iam get-open-id-connect-provider --open-id-connect-provider-arn "$ARN" --query 'Url' --output text || echo "")"
  if [ "$URL" = "token.actions.githubusercontent.com" ] || [ "$URL" = "https://token.actions.githubusercontent.com" ]; then
    [ $FOUND -eq 0 ] && echo "Found OIDC provider(s) for token.actions.githubusercontent.com:"
    echo " - $ARN"
    FOUND=1
    TO_DELETE="$TO_DELETE $ARN"
  fi
done
if [ $FOUND -eq 1 ]; then
  if confirm "Delete the OIDC provider(s) above? This will break roles trusting them until re-created."; then
    for ARN in $TO_DELETE; do
      aws_cli iam delete-open-id-connect-provider --open-id-connect-provider-arn "$ARN"
      echo "Deleted $ARN"
    done
  else
    echo "Aborting."; exit 1
  fi
else
  echo "No existing providers for token.actions.githubusercontent.com found."
fi

# 2) Re-create provider (ignore error if exists)
echo ">>> Creating OIDC provider for token.actions.githubusercontent.com…"
aws_cli iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" >/dev/null || true
echo "Created (or already existed) OIDC provider."

# 3) Create/Update the global role trust policy
echo ">>> Creating/Updating IAM role trust policy…"
TRUST_JSON="$(mktemp)"
cat > "$TRUST_JSON" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "${OIDC_ARN}" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
        "token.actions.githubusercontent.com:sub": "repo:${OWNER}/${REPO}:environment:${ENVIRONMENT}"
      }
    }
  }]
}
EOF

if aws_cli iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws_cli iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "file://${TRUST_JSON}"
  echo "Updated role trust policy: $ROLE_NAME"
else
  aws_cli iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://${TRUST_JSON}" \
    --description "GitHub OIDC role for GLOBAL Terraform (ECR-only + TF state)" >/dev/null
  echo "Created role: $ROLE_NAME"
fi
rm -f "$TRUST_JSON"

# 4a) TF state policy
echo ">>> Applying inline policy: TFStateAccess"
POL_TFSTATE="$(mktemp)"
cat > "$POL_TFSTATE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${STATE_BUCKET}",
      "Condition": { "StringLike": { "s3:prefix": ["${STATE_PREFIX}*"] } }
    },
    { "Effect": "Allow",
      "Action": ["s3:GetObject","s3:PutObject","s3:DeleteObject"],
      "Resource": "arn:aws:s3:::${STATE_BUCKET}/${STATE_PREFIX}*"
    },
    { "Effect": "Allow",
      "Action": ["dynamodb:DescribeTable","dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem","dynamodb:UpdateItem"],
      "Resource": "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${LOCK_TABLE}"
    }
  ]
}
EOF
aws_cli iam put-role-policy --role-name "$ROLE_NAME" --policy-name TFStateAccess --policy-document "file://${POL_TFSTATE}"
rm -f "$POL_TFSTATE"

# 4b) ECR-only policy
echo ">>> Applying inline policy: GlobalECROnly"
POL_ECR="$(mktemp)"
cat > "$POL_ECR" <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "EcrRepoManage",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository","ecr:DeleteRepository","ecr:DescribeRepositories","ecr:ListImages",
        "ecr:TagResource","ecr:UntagResource","ecr:PutLifecyclePolicy","ecr:GetLifecyclePolicy",
        "ecr:PutImageTagMutability","ecr:SetRepositoryPolicy","ecr:GetRepositoryPolicy"
      ],
      "Resource": "*"
    },
    { "Sid": "EcrImagePushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability","ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart","ecr:CompleteLayerUpload","ecr:PutImage","ecr:BatchGetImage",
        "ecr:DescribeImages","ecr:GetDownloadUrlForLayer","ecr:BatchDeleteImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF
aws_cli iam put-role-policy --role-name "$ROLE_NAME" --policy-name GlobalECROnly --policy-document "file://${POL_ECR}"
rm -f "$POL_ECR"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo
echo ">>> Done."
echo "Role ARN   : ${ROLE_ARN}"
echo "State S3   : s3://${STATE_BUCKET}/${STATE_PREFIX}"
echo "Lock table : ${LOCK_TABLE}"
