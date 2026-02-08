#!/bin/bash

# Auth Service ECR Push & ECS Deploy Script
# Pushes auth service image to ECR and deploys to Fargate

set -e

# Configuration
AWS_ACCOUNT_ID="247523262683"
AWS_REGION="us-east-1"
SERVICE_NAME="auth"
ECR_REPO_NAME="fargate-ecommerce-auth"
ECS_CLUSTER_NAME="fargate-ecommerce"
ECS_SERVICE_NAME="fargate-ecommerce-auth"
TASK_FAMILY="fargate-ecommerce-auth"
IMAGE_TAG="latest"

echo "🔄 Auth Service Deployment Pipeline"
echo "===================================="
echo "Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Service: $SERVICE_NAME"
echo ""

# Step 1: Check if ECR repository exists, create if not
echo "📦 Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" &>/dev/null; then
    echo "   Creating ECR repository: $ECR_REPO_NAME"
    aws ecr create-repository \
        --repository-name "$ECR_REPO_NAME" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true
else
    echo "   ✓ ECR repository exists"
fi

# Step 2: Authenticate Docker with ECR
echo ""
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Step 3: Build Docker image
echo ""
echo "🔨 Building Docker image..."
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_URI="$ECR_REGISTRY/$ECR_REPO_NAME:$IMAGE_TAG"

docker build -t "$IMAGE_URI" "./services/$SERVICE_NAME/"

# Step 4: Push to ECR
echo ""
echo "📤 Pushing image to ECR..."
docker push "$IMAGE_URI"
echo "   ✓ Image pushed: $IMAGE_URI"

# Step 5: Create CloudWatch Log Group if it doesn't exist
echo ""
echo "📋 Setting up CloudWatch Logs..."
LOG_GROUP="/ecs/fargate-ecommerce-auth"
if ! aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$AWS_REGION" &>/dev/null; then
    echo "   Creating log group: $LOG_GROUP"
    aws logs create-log-group --log-group-name "$LOG_GROUP" --region "$AWS_REGION"
    aws logs put-retention-policy --log-group-name "$LOG_GROUP" --retention-in-days 30 --region "$AWS_REGION"
else
    echo "   ✓ Log group exists"
fi

# Step 6: Register task definition
echo ""
echo "📝 Registering ECS task definition..."
aws ecs register-task-definition \
    --cli-input-json file://infrastructure/ecs/auth-task-def.json \
    --region "$AWS_REGION"
echo "   ✓ Task definition registered"

# Step 7: Check if ECS service exists
echo ""
echo "🚀 Checking ECS service..."

# VPC Configuration (discovered from your AWS account)
SUBNET_1="subnet-059633f038be56c0e"
SUBNET_2="subnet-08d94bd4acaa5c094"
SECURITY_GROUP="sg-0af532423ad9f9280"

if aws ecs describe-services --cluster "$ECS_CLUSTER_NAME" --services "$ECS_SERVICE_NAME" --region "$AWS_REGION" 2>/dev/null | grep -q "serviceName"; then
    echo "   Updating existing service..."
    aws ecs update-service \
        --cluster "$ECS_CLUSTER_NAME" \
        --service "$ECS_SERVICE_NAME" \
        --task-definition "$TASK_FAMILY:1" \
        --force-new-deployment \
        --region "$AWS_REGION"
    echo "   ✓ Service updated and redeploying"
else
    echo "   Creating new ECS service..."
    aws ecs create-service \
        --cluster "$ECS_CLUSTER_NAME" \
        --service-name "$ECS_SERVICE_NAME" \
        --task-definition "$TASK_FAMILY:1" \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
        --region "$AWS_REGION"
    echo "   ✓ Service created"
fi

echo ""
echo "✅ Auth Service Deployment Complete!"
echo ""
echo "📊 Service Status:"
aws ecs describe-services \
    --cluster "$ECS_CLUSTER_NAME" \
    --services "$ECS_SERVICE_NAME" \
    --region "$AWS_REGION" \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
    --output table

echo ""
echo "🔍 View logs:"
echo "   aws logs tail /ecs/fargate-ecommerce-auth --follow --region $AWS_REGION"
