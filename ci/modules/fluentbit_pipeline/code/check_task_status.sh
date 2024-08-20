#!/bin/bash

PREFIX=$1
PROFILE=$2
VPC_NAME="${PREFIX}-vpc"
SECURITY_GROUP_NAME="${PREFIX}-frontend-ecs-sg"
CLUSTER_NAME="${PREFIX}-frontend-cluster"
TASK="${PREFIX}-frontend-ecs-task"

VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$VPC_NAME --query 'Vpcs[0].VpcId' --profile $PROFILE)

SUBNET_GROUP_ID=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --profile $PROFILE )

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=group-name,Values=$SECURITY_GROUP_NAME --query 'SecurityGroups[0].GroupId'  --profile $PROFILE)

JSON_STRING="{\"awsvpcConfiguration\": {\"subnets\": ${SUBNET_GROUP_ID}, \"securityGroups\": [${SECURITY_GROUP_ID}],\"assignPublicIp\":\"DISABLED\"}}"

TASK_ID=$(aws ecs run-task  --cluster $CLUSTER_NAME  --task-definition $TASK  \
    --network-configuration "${JSON_STRING}" \
    --launch-type "FARGATE" --query 'tasks[0].containers[0].taskArn'  --profile $PROFILE | tr -d '"' )

STATUS=$(aws ecs describe-tasks  --cluster $CLUSTER_NAME --tasks $TASK_ID --query 'tasks[0].containers[0].lastStatus' --profile $PROFILE)

declare -i sleep_count=0

while [[ $STATUS == "\"PENDING\"" ]]; do
echo "${TASK_ID}  IS PENDING, WAITING FOR STATUS TO CHANGE"
echo "...sleep for 30 seconds"
sleep 30
(( ++sleep_count ))

STATUS=$(aws ecs describe-tasks  --cluster $CLUSTER_NAME --tasks $TASK_ID --query 'tasks[0].containers[0].lastStatus' --profile $PROFILE )
if [[ $STATUS == "\"RUNNING\"" ]]; then
  # check that a running does not not consequently stop
  echo "${TASK_ID} << TASK IS RUNNING...WAIT ANOTHER 10 seconds"
  sleep 10
  UPDATE_STATUS=$(aws ecs describe-tasks  --cluster $CLUSTER_NAME --tasks $TASK_ID --query 'tasks[0].containers[0].lastStatus' --profile $PROFILE)
 if [[ $UPDATE_STATUS == "\"RUNNING\"" ]]; then
  echo "${TASK_ID} << TASK IS STILL RUNNING"
  exit 0
 elif [[ $UPDATE_STATUS == "\"STOPPED\"" ]]; then
  echo "${TASK_ID} TASK FAILED TO START"
  exit 1
 fi
elif [[ $STATUS == "\"STOPPED\"" ]]; then
 echo "${TASK_ID} TASK FAILED TO START"
 exit 1
fi

# Give up waiting after half an hour and fail the pipeline
if [[ $sleep_count -ge 60 ]]; then
  echo "${TASK_ID} TASK HAS NOT STARTED AFTER 30 MINUTES"
  exit 1
fi

done

# Catch for if task wasn't PENDING at the start of the loop, or has some unexpected value at the end
if [[ $STATUS != "RUNNING" ]]; then
  echo "${TASK_ID} TASK STATUS IS $STATUS AND NOT RUNNING"
  exit 1
fi
