#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="eu-central-1"
CLUSTER_NAME="listservice-ci"

echo "============================"
echo " 🧹 Cleaning CI Environment "
echo "============================"

# 1. Delete ECS Services
echo "🔎 ECS Services..."
SERVICES=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --query "serviceArns[]" --output text || true)
if [[ -n "$SERVICES" ]]; then
  for svc in $SERVICES; do
    echo "⚡ Deleting service: $svc"
    aws ecs delete-service --cluster "$CLUSTER_NAME" --service "$svc" --force --region "$AWS_REGION" || true
  done
fi

# 2. Delete ECS Cluster
echo "🔎 ECS Cluster..."
CLUSTERS=$(aws ecs list-clusters --region "$AWS_REGION" --query "clusterArns[]" --output text || true)
for cl in $CLUSTERS; do
  if [[ "$cl" == *"$CLUSTER_NAME"* ]]; then
    echo "⚡ Deleting cluster: $cl"
    aws ecs delete-cluster --cluster "$cl" --region "$AWS_REGION" || true
  fi
done

# 3. Deregister Task Definitions
echo "🔎 ECS Task Definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix "$CLUSTER_NAME-task" --region "$AWS_REGION" --query "taskDefinitionArns[]" --output text || true)
for td in $TASK_DEFS; do
  echo "⚡ Deregistering task definition: $td"
  aws ecs deregister-task-definition --task-definition "$td" --region "$AWS_REGION" || true
done

# 4. Delete Target Groups
echo "🔎 ALB Target Groups..."
TGS=$(aws elbv2 describe-target-groups --region "$AWS_REGION" --query "TargetGroups[?contains(TargetGroupName, '${CLUSTER_NAME}-tg')].TargetGroupArn" --output text || true)
for tg in $TGS; do
  echo "⚡ Deleting target group: $tg"
  aws elbv2 delete-target-group --target-group-arn "$tg" --region "$AWS_REGION" || true
done

# 5. Delete Load Balancers
echo "🔎 Load Balancers..."
ALBS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?contains(LoadBalancerName, '${CLUSTER_NAME}-alb')].LoadBalancerArn" --output text || true)
for alb in $ALBS; do
  echo "⚡ Deleting load balancer: $alb"
  aws elbv2 delete-load-balancer --load-balancer-arn "$alb" --region "$AWS_REGION" || true
done

# 6. Delete ENIs tied to the SG
echo "🔎 Security Groups & ENIs..."
SG_IDS=$(aws ec2 describe-security-groups --region "$AWS_REGION" --query "SecurityGroups[?contains(GroupName, '${CLUSTER_NAME}')].GroupId" --output text || true)
for sg in $SG_IDS; do
  ENIS=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$sg" --region "$AWS_REGION" --query "NetworkInterfaces[].NetworkInterfaceId" --output text || true)
  for eni in $ENIS; do
    echo "⚡ Deleting ENI: $eni"
    aws ec2 delete-network-interface --network-interface-id "$eni" --region "$AWS_REGION" || true
  done
done

for sg in $SG_IDS; do
  echo "⚡ Deleting Security Group: $sg"
  aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" || true
done

# 7. Delete VPC and networking
echo "🔎 VPC Cleanup..."
VPCS=$(aws ec2 describe-vpcs --region "$AWS_REGION" --query "Vpcs[?Tags[?Value=='$CLUSTER_NAME']].VpcId" --output text || true)

for vpc in $VPCS; do
  echo "⚡ Cleaning VPC: $vpc"

  # Detach and delete IGWs
  IGWS=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[].InternetGatewayId" --output text || true)
  for igw in $IGWS; do
    echo "⚡ Detaching & deleting IGW: $igw"
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region "$AWS_REGION" || true
    aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$AWS_REGION" || true
  done

  # Delete Subnets
  SUBNETS=$(aws ec2 describe-subnets --region "$AWS_REGION" --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" --output text || true)
  for sn in $SUBNETS; do
    echo "⚡ Deleting Subnet: $sn"
    aws ec2 delete-subnet --subnet-id "$sn" --region "$AWS_REGION" || true
  done

  # Delete Route Tables
  RTBS=$(aws ec2 describe-route-tables --region "$AWS_REGION" --filters "Name=vpc-id,Values=$vpc" --query "RouteTables[].RouteTableId" --output text || true)
  for rtb in $RTBS; do
    MAIN=$(aws ec2 describe-route-tables --region "$AWS_REGION" --route-table-ids "$rtb" --query "RouteTables[0].Associations[?Main].Main" --output text)
    if [[ "$MAIN" != "True" ]]; then
      echo "⚡ Deleting Route Table: $rtb"
      aws ec2 delete-route-table --route-table-id "$rtb" --region "$AWS_REGION" || true
    fi
  done

  # Delete VPC
  echo "⚡ Deleting VPC: $vpc"
  aws ec2 delete-vpc --vpc-id "$vpc" --region "$AWS_REGION" || true
done

echo "✅ CI environment ($CLUSTER_NAME) cleanup complete!"
