#!/usr/bin/env bash
# aws-view.sh - see everything the three stacks created, using only the AWS CLI.
# Usage: ./scripts/aws-view.sh [project_name] [region]
set -euo pipefail
P="${1:-demo}"; R="${2:-us-east-1}"; export AWS_DEFAULT_REGION="$R"

echo "=== VPC ==="
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$P" \
  --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock,Name:Tags[?Key==`Name`]|[0].Value}' --output table
echo "=== Subnets ==="
aws ec2 describe-subnets --filters "Name=tag:Project,Values=$P" \
  --query 'Subnets[].{Id:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,Tier:Tags[?Key==`Tier`]|[0].Value}' --output table
echo "=== Route Tables ==="
aws ec2 describe-route-tables --filters "Name=tag:Project,Values=$P" \
  --query 'RouteTables[].{Id:RouteTableId,Name:Tags[?Key==`Name`]|[0].Value,Routes:Routes[].DestinationCidrBlock}' --output table
echo "=== VPC Endpoints ==="
aws ec2 describe-vpc-endpoints --filters "Name=tag:Project,Values=$P" \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}' --output table
echo "=== Security Groups ==="
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=$P" \
  --query 'SecurityGroups[].{Id:GroupId,Name:GroupName}' --output table
echo "=== Secret ==="
aws secretsmanager describe-secret --secret-id "$P/db-credentials" --query '{Name:Name,Arn:ARN}' --output table 2>/dev/null || echo "(none)"
echo "=== RDS ==="
aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '$P')].{Id:DBInstanceIdentifier,Engine:Engine,Ver:EngineVersion,Status:DBInstanceStatus,Endpoint:Endpoint.Address}" --output table
echo "=== IAM ==="
aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, '$P')].{Profile:InstanceProfileName,Role:Roles[0].RoleName}" --output table
echo "=== Launch Templates ==="
aws ec2 describe-launch-templates --filters "Name=tag:Project,Values=$P" \
  --query 'LaunchTemplates[].{Id:LaunchTemplateId,Name:LaunchTemplateName}' --output table
echo "=== Auto Scaling Group ==="
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, '$P')].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances[].InstanceId}" --output table
echo "=== EC2 Instances ==="
aws ec2 describe-instances --filters "Name=tag:Project,Values=$P" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,PrivateIp:PrivateIpAddress,Name:Tags[?Key==`Name`]|[0].Value}' --output table
echo "=== SSM-managed (can you log in?) ==="
aws ssm describe-instance-information --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus}' --output table
