#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# GitHub OIDC → AWS IAM role for Terraform CI (one-time setup)
# EDIT the defaults below or pass flags to override.
# ------------------------------------------------------------------------------

# --- Defaults (edit these) ---
PROFILE="sandbox"
REGION="eu-central-1"
OWNER="your-github-owner-or-org"
REPO="your-repo-name"
BRANCH="main"          # mutually exclusive with ENVIRONMENT (choose one)
ENVIRONMENT=""         # e.g. "ci" if you use GH Environments
ROLE_NAME="ListService-CI-Deploy"
STATE_PREFIX="listservice/ci/"
LOCK_TABLE="tf-state-lock"
STATE_BUCKET=""        # if empty, script will use tf-state-<account>-<region>

# --- Flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --role-name) ROLE_NAME="$2"; shift 2 ;;
    --state-prefix) STATE_PREFIX="$2"; shift 2 ;;
    --state-bucket) STATE_BUCKET="$2"; shift 2 ;;
    --lock-table) LOCK_TABLE="$2"; shift 2 ;;
    -h|--help)
      cat <<USAGE
Usage:
  $(basename "$0") [--profile sandbox] [--region eu-central-1]
                   --owner <gh_owner> --repo <gh_repo>
                  [--branch main | --environment ci]
                  [--role-name ListService-CI-Deploy]
                  [--state-prefix listservice/ci/]
                  [--state-bucket tf-state-<acct>-<region>]
                  [--lock-table tf-state-lock]
USAGE
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# --- Validation ---
if [[ -z "$OWNER" || -z "$REPO" ]]; then
  echo "ERROR: --owner and --repo are required (or set in script header)." >&2; exit 1
fi
if [[ -n "$BRANCH" && -n "$ENVIRONMENT" ]]; then
  echo "ERROR: Use either --branch OR --environment (not both)." >&2; exit 1
fi
if [[ -z "$BRANCH" && -z "$ENVIRONMENT" ]]; then
  echo "ERROR: Provide one of --branch or --environment." >&2; exit 1
fi

aws_cli() {
  aws --profile "$PROFILE" --region "$REGION" "$@"
}

echo ">>> Resolving AWS account..."
ACCOUNT_ID="$(aws_cli sts get-caller-identity --query Account --output text)"
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
[[ -z "$STATE_BUCKET" ]] && STATE_BUCKET="tf-state-${ACCOUNT_ID}-${REGION}"

echo "Account     : $ACCOUNT_ID"
echo "Region      : $REGION"
echo "Profile     : $PROFILE"
echo "Repo        : $OWNER/$REPO"
[[ -n "$BRANCH" ]] && echo "Trust scope : branch=$BRANCH"
[[ -n "$ENVIRONMENT" ]] && echo "Trust scope : environment=$ENVIRONMENT"
echo "Role name   : $ROLE_NAME"
echo "State S3    : s3://$STATE_BUCKET/$STATE_PREFIX"
echo "Lock table  : $LOCK_TABLE"

# 1) Ensure OIDC provider exists
echo ">>> Ensuring OIDC provider (token.actions.githubusercontent.com) exists…"
if aws_cli iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text | grep -q "$OIDC_ARN"; then
  echo "OIDC provider already present."
else
  aws_cli iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com >/dev/null
  echo "Created OIDC provider."
fi

# 2) Create/Update the IAM role with trust policy
echo ">>> Creating/Updating IAM role trust policy…"
TRUST_JSON="$(mktemp)"
if [[ -n "$BRANCH" ]]; then
  cat > "$TRUST_JSON" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "${OIDC_ARN}" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:${OWNER}/${REPO}:ref:refs/heads/${BRANCH}" }
    }
  }]
}
EOF
else
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
fi

if aws_cli iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws_cli iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "file://${TRUST_JSON}"
  echo "Updated role trust policy: $ROLE_NAME"
else
  aws_cli iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://${TRUST_JSON}" \
    --description "GitHub OIDC role for Terraform CI deploys" >/dev/null
  echo "Created role: $ROLE_NAME"
fi
rm -f "$TRUST_JSON"

# 3) Inline policy: Terraform state (S3 + DynamoDB lock)
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
aws_cli iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name TFStateAccess \
  --policy-document "file://${POL_TFSTATE}"
rm -f "$POL_TFSTATE"

# 4) Inline policy: least-priv infra for your CI stack
echo ">>> Applying inline policy: ListServiceCIInfra"
POL_INFRA="$(mktemp)"
cat > "$POL_INFRA" <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect":"Allow", "Action":[
        "ec2:CreateVpc","ec2:DeleteVpc","ec2:Describe*",
        "ec2:CreateSubnet","ec2:DeleteSubnet",
        "ec2:CreateRouteTable","ec2:DeleteRouteTable","ec2:AssociateRouteTable","ec2:DisassociateRouteTable","ec2:CreateRoute","ec2:DeleteRoute",
        "ec2:CreateInternetGateway","ec2:DeleteInternetGateway","ec2:AttachInternetGateway","ec2:DetachInternetGateway",
        "ec2:CreateSecurityGroup","ec2:DeleteSecurityGroup","ec2:AuthorizeSecurityGroupIngress","ec2:AuthorizeSecurityGroupEgress","ec2:RevokeSecurityGroupIngress","ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags","ec2:DeleteTags"
      ], "Resource":"*" },

    { "Effect":"Allow", "Action":[
        "elasticloadbalancing:CreateLoadBalancer","elasticloadbalancing:DeleteLoadBalancer","elasticloadbalancing:CreateTargetGroup","elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:CreateListener","elasticloadbalancing:DeleteListener","elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:RegisterTargets","elasticloadbalancing:DeregisterTargets","elasticloadbalancing:Describe*"
      ], "Resource":"*" },

    { "Effect":"Allow", "Action":[
        "ecs:CreateCluster","ecs:DeleteCluster","ecs:Describe*","ecs:List*",
        "ecs:RegisterTaskDefinition","ecs:DeregisterTaskDefinition",
        "ecs:CreateService","ecs:UpdateService","ecs:DeleteService"
      ], "Resource":"*" },

    { "Effect":"Allow", "Action":[
        "iam:CreateRole","iam:DeleteRole","iam:GetRole","iam:PassRole",
        "iam:AttachRolePolicy","iam:DetachRolePolicy","iam:PutRolePolicy","iam:DeleteRolePolicy"
      ], "Resource":"*" },

    { "Effect":"Allow", "Action":[
        "logs:CreateLogGroup","logs:DeleteLogGroup","logs:PutRetentionPolicy","logs:DescribeLogGroups"
      ], "Resource":"*" },

    { "Effect":"Allow", "Action":[
        "application-autoscaling:RegisterScalableTarget","application-autoscaling:DeregisterScalableTarget",
        "application-autoscaling:PutScalingPolicy","application-autoscaling:DeleteScalingPolicy",
        "application-autoscaling:Describe*"
      ], "Resource":"*" }
  ]
}
EOF
aws_cli iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name ListServiceCIInfra \
  --policy-document "file://${POL_INFRA}"
rm -f "$POL_INFRA"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo ">>> Done."
echo "Role ARN   : ${ROLE_ARN}"
echo "OIDC Prov. : ${OIDC_ARN}"
echo "State S3   : s3://${STATE_BUCKET}/${STATE_PREFIX}"
echo "Lock table : ${LOCK_TABLE}"
