#!/bin/bash
# List every AWS resource created by the simple-website example (by Project tag).
set -euo pipefail
source "$(dirname "$0")/common.sh"

echo "Project: $PROJECT   Region: $REGION"

header "EC2 Instances"
aws ec2 describe-instances --region "$REGION" \
  --filters "$TAG_FILTER" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,LaunchTemplate:Tags[?Key==`aws:ec2launchtemplate:id`]|[0].Value}' \
  --output table

header "Launch Templates"
aws ec2 describe-launch-templates --region "$REGION" \
  --filters "$TAG_FILTER" \
  --query 'LaunchTemplates[].{ID:LaunchTemplateId,Name:LaunchTemplateName,Default:DefaultVersionNumber,Latest:LatestVersionNumber,Created:CreateTime}' \
  --output table

header "Launch Template Versions (latest)"
for lt in $(aws ec2 describe-launch-templates --region "$REGION" --filters "$TAG_FILTER" \
              --query 'LaunchTemplates[].LaunchTemplateId' --output text); do
  aws ec2 describe-launch-template-versions --region "$REGION" --launch-template-id "$lt" --versions '$Latest' \
    --query 'LaunchTemplateVersions[].{ID:LaunchTemplateId,Ver:VersionNumber,AMI:LaunchTemplateData.ImageId,Type:LaunchTemplateData.InstanceType,IMDSv2:LaunchTemplateData.MetadataOptions.HttpTokens,PublicIP:LaunchTemplateData.NetworkInterfaces[0].AssociatePublicIpAddress}' \
    --output table
done

header "Security Groups"
aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=${PROJECT}-web" \
  --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,VPC:VpcId,Ingress:IpPermissions[].join(`/`,[to_string(FromPort),IpProtocol,IpRanges[0].CidrIp])|join(`, `,@)}' \
  --output table

header "Elastic IPs"
aws ec2 describe-addresses --region "$REGION" \
  --filters "$TAG_FILTER" \
  --query 'Addresses[].{AllocationId:AllocationId,PublicIP:PublicIp,Instance:InstanceId}' \
  --output table

header "EBS Volumes"
aws ec2 describe-volumes --region "$REGION" \
  --filters "$TAG_FILTER" \
  --query 'Volumes[].{ID:VolumeId,Size:Size,Type:VolumeType,Encrypted:Encrypted,State:State,Instance:Attachments[0].InstanceId}' \
  --output table

header "Network Interfaces"
aws ec2 describe-network-interfaces --region "$REGION" \
  --filters "$TAG_FILTER" \
  --query 'NetworkInterfaces[].{ID:NetworkInterfaceId,Status:Status,PrivateIP:PrivateIpAddress,PublicIP:Association.PublicIp,Instance:Attachment.InstanceId}' \
  --output table

header "Website URL(s)"
aws ec2 describe-instances --region "$REGION" \
  --filters "$TAG_FILTER" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].PublicIpAddress' --output text | tr '\t' '\n' | sed 's#^#http://#'
