#!/usr/bin/env bash
# aws-destroy.sh - EMERGENCY cleanup with the AWS CLI, in reverse stack order
# (compute -> database -> network). Prefer `terraform destroy` in each folder.
# Usage: ./scripts/aws-destroy.sh [project_name] [region]
set -uo pipefail
P="${1:-demo}"; R="${2:-us-east-1}"; export AWS_DEFAULT_REGION="$R"

read -r -p "DELETE all '$P' resources in $R? Type 'yes': " OK
[ "$OK" = "yes" ] || { echo "Aborted."; exit 1; }

echo "##### STACK 3: compute #####"
for ASG in $(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, '$P')].AutoScalingGroupName" --output text); do
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG" --min-size 0 --max-size 0 --desired-capacity 0
  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$ASG" --force-delete
done
IDS=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=$P" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text)
if [ -n "$IDS" ]; then aws ec2 terminate-instances --instance-ids $IDS; aws ec2 wait instance-terminated --instance-ids $IDS; fi
for LT in $(aws ec2 describe-launch-templates --filters "Name=tag:Project,Values=$P" --query 'LaunchTemplates[].LaunchTemplateId' --output text); do
  aws ec2 delete-launch-template --launch-template-id "$LT"
done
for PROF in $(aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, '$P')].InstanceProfileName" --output text); do
  for ROLE in $(aws iam get-instance-profile --instance-profile-name "$PROF" --query 'InstanceProfile.Roles[].RoleName' --output text); do
    aws iam remove-role-from-instance-profile --instance-profile-name "$PROF" --role-name "$ROLE"
  done
  aws iam delete-instance-profile --instance-profile-name "$PROF"
done
for ROLE in $(aws iam list-roles --query "Roles[?contains(RoleName, '$P-app')].RoleName" --output text); do
  for POL in $(aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames' --output text); do
    aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POL"
  done
  for ARN in $(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn' --output text); do
    aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$ARN"
  done
  aws iam delete-role --role-name "$ROLE"
done

echo "##### STACK 2: database #####"
for DB in $(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '$P')].DBInstanceIdentifier" --output text); do
  aws rds delete-db-instance --db-instance-identifier "$DB" --skip-final-snapshot --delete-automated-backups
  aws rds wait db-instance-deleted --db-instance-identifier "$DB"
done
for SG in $(aws rds describe-db-subnet-groups --query "DBSubnetGroups[?contains(DBSubnetGroupName, '$P')].DBSubnetGroupName" --output text); do
  aws rds delete-db-subnet-group --db-subnet-group-name "$SG"
done
aws secretsmanager delete-secret --secret-id "$P/db-credentials" --force-delete-without-recovery 2>/dev/null || true

echo "##### STACK 1: network #####"
VPC=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$P" --query 'Vpcs[0].VpcId' --output text)
if [ "$VPC" != "None" ] && [ -n "$VPC" ]; then
  for EP in $(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC" --query 'VpcEndpoints[].VpcEndpointId' --output text); do
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$EP"
  done
  echo "waiting for endpoint network cards to release..."; sleep 60
  for i in 1 2 3; do
    for G in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
      aws ec2 delete-security-group --group-id "$G" 2>/dev/null && echo "deleted $G"
    done
    sleep 10
  done
  for SN in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC" --query 'Subnets[].SubnetId' --output text); do
    aws ec2 delete-subnet --subnet-id "$SN"
  done
  for RT in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    aws ec2 delete-route-table --route-table-id "$RT"
  done
  aws ec2 delete-vpc --vpc-id "$VPC" && echo "VPC $VPC deleted."
fi
echo "Done. Re-run ./scripts/aws-view.sh $P $R to confirm."
