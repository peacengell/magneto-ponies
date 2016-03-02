#!/bin/bash

# The following IAM roles are required:
#   AmazonEC2ReadOnlyAccess

region=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/ | sed '$ s/.$//'`
uuid=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
rackuuid=`/usr/local/bin/aws ec2 describe-tags --region ${region} --filters "Name=resource-id,Values=${uuid}" "Name=key,Values=rackuuid" --query 'Tags[*].Value[]' --output text`
elblist=`/usr/local/bin/aws elb describe-load-balancers --region ${region} --query 'LoadBalancerDescriptions[].LoadBalancerName[]' --output text`
IFS=$'\t' read -ra elbcheck <<<"${elblist}"

for i in "${elbcheck[@]}"
do
  elbtag=`/usr/local/bin/aws elb describe-tags --load-balancer-name ${i} --region ${region} --query 'TagDescriptions[].Tags[].Value[]' --output text`

  if [[ ${elbtag} == *"${rackuuid}"* ]]
  then
    break
  fi
done

echo ${elbtag}
