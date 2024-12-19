#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <ecr_repo> <tag>"
    exit 1
fi

ECR_REPO=$1
TAG=$2
IMAGE=$ECR_REPO:$TAG

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_DOMAIN="$ACCOUNT_ID.dkr.ecr.us-east-2.amazonaws.com"
REPO="$ECR_DOMAIN/$IMAGE"
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $ECR_DOMAIN
docker build -t $IMAGE .
docker tag $IMAGE $REPO
docker push $REPO
