#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
PROFILE="sandbox"
REGION="eu-central-1"

OWNER="humayun-rashid"
REPO="withSecure-Assignment"
ENVIRONMENT="global"

ROLE_NAME="ListService-Global-Deploy"
STATE_PREFIX="listservice/global/"
LOCK_TABLE="tf-state-lock"
STATE_BUCKET=""
REPO_NAME="listservice-global"

ASSUME_YES=false

# --- Flags ---
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
    --repo-name) REPO_NAME="$2"; shift 2 ;;
    --yes|-y) ASSUME_YES=true; shift 1 ;;
    -h|--help) echo "Usage: $0 [--profile p] [--region r] [--owner o] [--repo r] [--environment e] [--role-name n] [--repo-name n] [--state-prefix p] [--state-bucket b] [--lock-table t] [--yes]"; exit 0;;
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
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

echo "Account     : $ACCOUNT_ID"
echo "Region      : $REGION"
echo "Profile     : $PROFILE"
echo "Repo        : ${OWNER}/${REPO}"
echo "Trust scope : environment=${ENVIRONMENT}"
echo "Role name   : $ROLE_NAME"
echo "Repo name   : $REPO_NAME"
echo "State S3    : s3://${STATE_BUCKET}/${STATE_PREFIX}"
echo "Lock table  : ${LOCK_TABLE}"
echo

# --- Ensure OIDC provider exists ---
if ! aws_cli iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  echo ">>> Creating OIDC provider for GitHub…"
  aws_cli iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --client-id-list "sts.amazonaws.com" >/dev/null
else
  echo "OIDC provider already exists: $OIDC_ARN"
fi

# --- Role Trust Policy ---
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
  aws_cli iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "file://${TRUST_JSON}"
  echo "Updated trust policy for role: $ROLE_NAME"
else
  aws_cli iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://${TRUST_JSON}" \
    --description "GitHub OIDC role for Terraform + ECR" >/dev/null
  echo "Created new role: $ROLE_NAME"
fi
rm -f "$TRUST_JSON"

# --- Inline Policy: Terraform State Access ---
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
      "Action": ["dynamodb:*"],
      "Resource": "arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${LOCK_TABLE}"
    }
  ]
}
EOF
aws_cli iam put-role-policy --role-name "$ROLE_NAME" \
  --policy-name TFStateAccess \
  --policy-document "file://${POL_TFSTATE}"
rm -f "$POL_TFSTATE"

# --- Inline Policy: ECR Access ---
POL_ECR="$(mktemp)"
cat > "$POL_ECR" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "arn:aws:ecr:${REGION}:${ACCOUNT_ID}:repository/${REPO_NAME}"
    },
    { "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    }
  ]
}
EOF
aws_cli iam put-role-policy --role-name "$ROLE_NAME" \
  --policy-name ECRAccess \
  --policy-document "file://${POL_ECR}"
rm -f "$POL_ECR"

# --- Inline Policy: CI Infra Access ---
POL_CI_INFRA="$(mktemp)"
cat > "$POL_CI_INFRA" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow",
      "Action": [
        "logs:ListTagsForResource",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    },
    { "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "arn:aws:iam::${ACCOUNT_ID}:role/listservice-ci-*"
    },
    { "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListTagsForResource"
      ],
      "Resource": "*"
    },
    { "Effect": "Allow",
      "Action": [
        "application-autoscaling:Describe*",
        "application-autoscaling:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
aws_cli iam put-role-policy --role-name "$ROLE_NAME" \
  --policy-name CIInfraAccess \
  --policy-document "file://${POL_CI_INFRA}"
rm -f "$POL_CI_INFRA"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo
echo "✅ Done."
echo "Role ARN   : ${ROLE_ARN}"
echo "State S3   : s3://${STATE_BUCKET}/${STATE_PREFIX}"
echo "Lock table : ${LOCK_TABLE}"
