#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="eu-central-1"
CLUSTER_NAME="listservice-ci"
STACK_TAG="ListService"

echo "============================"
echo " 🧹 Cleaning CI Environment "
echo "============================"

# Retry wrapper
retry() {
  local n=0
  until [ $n -ge 5 ]; do
    "$@" && break
    n=$((n+1))
    echo "Retry $n for command: $*"
    sleep 5
  done
}

# --- ECS ---
echo "🔎 ECS Services..."
SERVICES=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --query "serviceArns[]" --output text || true)
for svc in $SERVICES; do
  echo "⚡ Deleting ECS service: $svc"
  retry aws ecs update-service --cluster "$CLUSTER_NAME" --service "$svc" --desired-count 0 --region "$AWS_REGION" || true
  retry aws ecs delete-service --cluster "$CLUSTER_NAME" --service "$svc" --force --region "$AWS_REGION" || true
done

echo "🔎 ECS Cluster..."
if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$AWS_REGION" --query "clusters[0].status" --output text 2>/dev/null | grep -q ACTIVE; then
  retry aws ecs delete-cluster --cluster "$CLUSTER_NAME" --region "$AWS_REGION" || true
fi

echo "🔎 ECS Task Definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix "${CLUSTER_NAME}-task" --region "$AWS_REGION" --query "taskDefinitionArns[]" --output text || true)
for td in $TASK_DEFS; do
  echo "⚡ Deregistering task definition: $td"
  retry aws ecs deregister-task-definition --task-definition "$td" --region "$AWS_REGION" || true
done

# --- Logs ---
echo "🔎 CloudWatch Log Groups..."
LOG_GROUPS=$(aws logs describe-log-groups --log-group-name-prefix "/ecs/${CLUSTER_NAME}" --region "$AWS_REGION" --query "logGroups[].logGroupName" --output text || true)
for lg in $LOG_GROUPS; do
  echo "⚡ Deleting Log Group: $lg"
  retry aws logs delete-log-group --log-group-name "$lg" --region "$AWS_REGION" || true
done

# --- Load Balancer + Target Groups ---
echo "🔎 Load Balancers..."
ALBS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?contains(LoadBalancerName, '${CLUSTER_NAME}-alb')].LoadBalancerArn" --output text || true)
for alb in $ALBS; do
  echo "⚡ Cleaning ALB: $alb"
  LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn "$alb" --region "$AWS_REGION" --query "Listeners[].ListenerArn" --output text || true)
  for l in $LISTENERS; do
    echo "⚡ Deleting Listener: $l"
    retry aws elbv2 delete-listener --listener-arn "$l" --region "$AWS_REGION" || true
  done
  retry aws elbv2 delete-load-balancer --load-balancer-arn "$alb" --region "$AWS_REGION" || true
done

echo "🔎 ALB Target Groups..."
TGS=$(aws elbv2 describe-target-groups --region "$AWS_REGION" --query "TargetGroups[?contains(TargetGroupName, '${CLUSTER_NAME}-tg')].TargetGroupArn" --output text || true)
for tg in $TGS; do
  echo "⚡ Deleting Target Group: $tg"
  retry aws elbv2 delete-target-group --target-group-arn "$tg" --region "$AWS_REGION" || true
done

# --- NAT / Networking ---
echo "🔎 NAT Gateways..."
NATS=$(aws ec2 describe-nat-gateways --region "$AWS_REGION" --filter "Name=tag:Name,Values=${CLUSTER_NAME}*" --query "NatGateways[].NatGatewayId" --output text || true)
for nat in $NATS; do
  echo "⚡ Deleting NAT Gateway: $nat"
  retry aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region "$AWS_REGION" || true
done

echo "🔎 Elastic IPs..."
EIPS=$(aws ec2 describe-addresses --region "$AWS_REGION" --query "Addresses[?Tags[?Value=='$CLUSTER_NAME']].AllocationId" --output text || true)
for eip in $EIPS; do
  echo "⚡ Releasing EIP: $eip"
  retry aws ec2 release-address --allocation-id "$eip" --region "$AWS_REGION" || true
done

echo "🔎 VPC Endpoints..."
VPCS=$(aws ec2 describe-vpcs --region "$AWS_REGION" --query "Vpcs[?Tags[?Value=='$CLUSTER_NAME']].VpcId" --output text || true)
for vpc in $VPCS; do
  EPS=$(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" --filters "Name=vpc-id,Values=$vpc" --query "VpcEndpoints[].VpcEndpointId" --output text || true)
  for ep in $EPS; do
    echo "⚡ Deleting VPC Endpoint: $ep"
    retry aws ec2 delete-vpc-endpoint --vpc-endpoint-id "$ep" --region "$AWS_REGION" || true
  done
done

# --- Security Groups / ENIs ---
echo "🔎 Security Groups & ENIs..."
SG_IDS=$(aws ec2 describe-security-groups --region "$AWS_REGION" --query "SecurityGroups[?contains(GroupName, '${CLUSTER_NAME}')].GroupId" --output text || true)
for sg in $SG_IDS; do
  ENIS=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$sg" --region "$AWS_REGION" --query "NetworkInterfaces[].NetworkInterfaceId" --output text || true)
  for eni in $ENIS; do
    echo "⚡ Deleting ENI: $eni"
    retry aws ec2 delete-network-interface --network-interface-id "$eni" --region "$AWS_REGION" || true
  done
  echo "⚡ Deleting Security Group: $sg"
  retry aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" || true
done

# --- VPCs ---
for vpc in $VPCS; do
  echo "⚡ Cleaning VPC: $vpc"

  # Internet Gateways
  IGWS=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[].InternetGatewayId" --output text || true)
  for igw in $IGWS; do
    echo "⚡ Detaching & deleting IGW: $igw"
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region "$AWS_REGION" || true
    retry aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$AWS_REGION" || true
  done

  # Subnets
  SUBNETS=$(aws ec2 describe-subnets --region "$AWS_REGION" --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" --output text || true)
  for sn in $SUBNETS; do
    echo "⚡ Deleting Subnet: $sn"
    retry aws ec2 delete-subnet --subnet-id "$sn" --region "$AWS_REGION" || true
  done

  # Route Tables
  RTBS=$(aws ec2 describe-route-tables --region "$AWS_REGION" --filters "Name=vpc-id,Values=$vpc" --query "RouteTables[].RouteTableId" --output text || true)
  for rtb in $RTBS; do
    MAIN=$(aws ec2 describe-route-tables --region "$AWS_REGION" --route-table-ids "$rtb" --query "RouteTables[0].Associations[?Main].Main" --output text)
    if [[ "$MAIN" != "True" ]]; then
      echo "⚡ Deleting Route Table: $rtb"
      retry aws ec2 delete-route-table --route-table-id "$rtb" --region "$AWS_REGION" || true
    fi
  done

  echo "⚡ Deleting VPC: $vpc"
  retry aws ec2 delete-vpc --vpc-id "$vpc" --region "$AWS_REGION" || true
done

# --- Observability ---
echo "🔎 CloudWatch Alarms..."
ALARMS=$(aws cloudwatch describe-alarms --region "$AWS_REGION" --query "MetricAlarms[?contains(AlarmName, '${CLUSTER_NAME}')].AlarmName" --output text || true)
for alarm in $ALARMS; do
  echo "⚡ Deleting Alarm: $alarm"
  retry aws cloudwatch delete-alarms --alarm-names "$alarm" --region "$AWS_REGION" || true
done

# --- ECR ---
echo "🔎 ECR Repositories..."
REPOS=$(aws ecr describe-repositories --region "$AWS_REGION" --query "repositories[?contains(repositoryName, '${STACK_TAG}')].repositoryName" --output text || true)
for repo in $REPOS; do
  echo "⚡ Deleting ECR repo: $repo"
  retry aws ecr delete-repository --repository-name "$repo" --force --region "$AWS_REGION" || true
done

# --- IAM Roles ---
echo "🔎 IAM Roles..."
for role in "${CLUSTER_NAME}-exec-role" "${CLUSTER_NAME}-task-role"; do
  if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
    echo "⚡ Detaching policies from $role"
    ATTACHED=$(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text || true)
    for pol in $ATTACHED; do
      retry aws iam detach-role-policy --role-name "$role" --policy-arn "$pol" || true
    done
    echo "⚡ Deleting IAM role: $role"
    retry aws iam delete-role --role-name "$role" || true
  fi
done

echo "✅ CI environment ($CLUSTER_NAME) cleanup complete!"
