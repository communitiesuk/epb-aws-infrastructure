#!/bin/bash

PROFILE=$1

aws ecs update-service --cluster "${PREFIX}-auth-cluster" --service "${PREFIX}-auth" --force-new-deployment --profile $PROFILE --region $AWS_REGION
aws ecs update-service --cluster "${PREFIX}-reg-api-cluster" --service "${PREFIX}-reg-api" --force-new-deployment --profile $PROFILE --region $AWS_REGION
aws ecs update-service --cluster "${PREFIX}-frontend-cluster" --service "${PREFIX}-frontend" --force-new-deployment --profile $PROFILE --region $AWS_REGION
aws ecs update-service --cluster "${PREFIX}-warehouse-cluster" --service "${PREFIX}-warehouse" --force-new-deployment --profile $PROFILE --region $AWS_REGION
aws ecs update-service --cluster "${PREFIX}-toggles-cluster" --service "${PREFIX}-toggles" --force-new-deployment --profile $PROFILE --region $AWS_REGION
