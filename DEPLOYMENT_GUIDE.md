# Auth Service Deployment & RDS Setup Guide

## 📋 Overview

This guide will help you deploy the **auth microservice** to AWS Fargate and provision a **PostgreSQL RDS instance** for the products and orders services.

**Timeline**: Target completion by Boss Day (Feb 13)
**Phase 1 (this sprint)**: Auth ECR push + ECS service deploy + RDS provision
**Phase 2**: CodePipeline setup + Stripe integration + ALB configuration

---

## 🚀 Quick Start (TL;DR)

```bash
# 1. Deploy Auth Service to Fargate
chmod +x scripts/deploy-auth.sh
./scripts/deploy-auth.sh

# 2. Provision RDS Postgres
chmod +x scripts/provision-rds.sh
./scripts/provision-rds.sh

# 3. Update Products/Orders task definitions (already done)
# Task definitions are ready in infrastructure/ecs/
```

---

## 📦 Part 1: Auth Service Deployment

### Prerequisites
- AWS CLI configured with appropriate IAM credentials
- Docker installed and running
- Access to ECR repository creation

### Step 1: Build and Push to ECR

The `deploy-auth.sh` script handles the complete ECR workflow:

```bash
./scripts/deploy-auth.sh
```

**What it does**:
1. ✅ Creates ECR repository if it doesn't exist
2. ✅ Authenticates Docker with ECR
3. ✅ Builds the auth service image
4. ✅ Pushes image to ECR
5. ✅ Creates CloudWatch log group
6. ✅ Registers ECS task definition
7. ✅ Creates or updates ECS service

**Manual alternative** (if script doesn't work):

```bash
# Authenticate
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin 247523262683.dkr.ecr.us-east-1.amazonaws.com

# Build
docker build -t 247523262683.dkr.ecr.us-east-1.amazonaws.com/fargate-ecommerce-auth:latest \
    ./services/auth/

# Push
docker push 247523262683.dkr.ecr.us-east-1.amazonaws.com/fargate-ecommerce-auth:latest

# Register task definition
aws ecs register-task-definition \
    --cli-input-json file://infrastructure/ecs/auth-task-def.json \
    --region us-east-1
```

### Step 2: Verify Auth Service Deployment

```bash
# Check service status
aws ecs describe-services \
    --cluster fargate-ecommerce \
    --services fargate-ecommerce-auth \
    --region us-east-1 \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
    --output table

# View logs
aws logs tail /ecs/fargate-ecommerce-auth --follow --region us-east-1

# Test the service (once running)
# Get the task IP from ECS console or:
aws ecs list-tasks --cluster fargate-ecommerce --region us-east-1
aws ecs describe-tasks --cluster fargate-ecommerce --tasks <TASK_ARN> --region us-east-1 \
    --query 'tasks[0].containerInstanceArn'

# Health check
curl http://<TASK_IP>:8000/health
```

---

## 🗄️ Part 2: RDS Postgres Provisioning

### Prerequisites
- VPC Security Group ID that allows inbound on port 5432
- RDS Subnet Group (use `default` or create one)
- Sufficient AWS permissions for RDS creation

### Step 1: Run RDS Provisioning Script

```bash
chmod +x scripts/provision-rds.sh

# Set security group (required!)
export VPC_SG_ID="sg-xxxxxxxx"  # Update with your security group

# Optional: Set custom DB password (otherwise random 32-char generated)
export DB_PASSWORD="your-secure-password"

./scripts/provision-rds.sh
```

**What it does**:
1. ✅ Creates RDS PostgreSQL instance (db.t4g.micro)
2. ✅ Waits for instance to be available (5-10 minutes)
3. ✅ Stores credentials in AWS Secrets Manager
4. ✅ Generates environment configuration files
5. ✅ Outputs connection string and next steps

### Step 2: Monitor RDS Creation

```bash
# Check status
aws rds describe-db-instances \
    --db-instance-identifier fargate-db \
    --region us-east-1 \
    --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
    --output table

# View logs
aws logs tail /aws/rds/instance/fargate-db/postgresql --follow --region us-east-1
```

### Step 3: Retrieve DB Endpoint

```bash
# Get endpoint
aws rds describe-db-instances \
    --db-instance-identifier fargate-db \
    --region us-east-1 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text

# Get full connection string from Secrets Manager
aws secretsmanager get-secret-value \
    --secret-id fargate/database \
    --region us-east-1 \
    --query 'SecretString' \
    --output text | jq '.url'
```

---

## 🔗 Part 3: Connect Products & Orders Services to RDS

The task definitions have been updated to use RDS:
- [products-task-def.json](../infrastructure/ecs/products-task-def.json)
- [orders-task-def.json](../infrastructure/ecs/orders-task-def.json)

Both services now pull `DATABASE_URL` from Secrets Manager: `arn:aws:secretsmanager:us-east-1:247523262683:secret:fargate/database:url::`

### Deploy Products Service with RDS

```bash
# Register new task definition
aws ecs register-task-definition \
    --cli-input-json file://infrastructure/ecs/products-task-def.json \
    --region us-east-1

# Update ECS service to use new task definition
aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-products \
    --task-definition fargate-ecommerce-products:2 \
    --force-new-deployment \
    --region us-east-1
```

### Deploy Orders Service with RDS

```bash
aws ecs register-task-definition \
    --cli-input-json file://infrastructure/ecs/orders-task-def.json \
    --region us-east-1

aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-orders \
    --task-definition fargate-ecommerce-orders:2 \
    --force-new-deployment \
    --region us-east-1
```

---

## 🛡️ Security Considerations

### 1. RDS Security Group
Ensure the security group attached to RDS allows inbound traffic from Fargate tasks:

```bash
# Example: Allow Fargate security group
aws ec2 authorize-security-group-ingress \
    --group-id <RDS_SG_ID> \
    --protocol tcp \
    --port 5432 \
    --source-group <FARGATE_SG_ID> \
    --region us-east-1
```

### 2. Secrets Manager Access
Verify IAM role has permission to read Secrets Manager:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:247523262683:secret:fargate/*"
    },
    {
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "arn:aws:kms:us-east-1:247523262683:key/*"
    }
  ]
}
```

### 3. Auth Secret Management
Update the auth service's SECRET_KEY:

```python
# Move from hardcoded to environment variable
import os
SECRET_KEY = os.getenv("SECRET_KEY", "change-this-in-production")
```

Then add to Secrets Manager:
```bash
aws secretsmanager create-secret \
    --name fargate/auth-keys \
    --secret-string '{"SECRET_KEY":"your-production-jwt-secret"}' \
    --region us-east-1
```

---

## 📊 Deployment Checklist

- [ ] **Auth Service**
  - [ ] `deploy-auth.sh` executed successfully
  - [ ] Image visible in ECR: `fargate-ecommerce-auth:latest`
  - [ ] Task definition registered: `fargate-ecommerce-auth`
  - [ ] ECS service running with desired count = 1
  - [ ] Health check responding: `GET /health → 200`

- [ ] **RDS PostgreSQL**
  - [ ] `provision-rds.sh` executed successfully
  - [ ] Instance status: `available`
  - [ ] Endpoint retrieved and documented
  - [ ] Credentials stored in Secrets Manager: `fargate/database`
  - [ ] Security group allows inbound port 5432

- [ ] **Products Service**
  - [ ] Task definition updated with `DATABASE_URL` secret
  - [ ] Service updated with new task definition
  - [ ] Logs show successful database connection

- [ ] **Orders Service**
  - [ ] Task definition updated with `DATABASE_URL` secret
  - [ ] Service updated with new task definition
  - [ ] Logs show successful database connection

---

## 🚨 Troubleshooting

### Auth Service Won't Start
```bash
# Check task logs
aws logs tail /ecs/fargate-ecommerce-auth --follow --region us-east-1

# Common issues:
# - Port already in use: Check other tasks on same security group
# - Image not found: Verify ECR push completed and image URI is correct
# - Network error: Check security group allows egress to 0.0.0.0
```

### RDS Creation Times Out
```bash
# Check RDS status
aws rds describe-db-instances \
    --db-instance-identifier fargate-db \
    --region us-east-1

# If stuck, may need to delete and retry:
aws rds delete-db-instance \
    --db-instance-identifier fargate-db \
    --skip-final-snapshot \
    --region us-east-1
```

### Services Can't Connect to RDS
```bash
# 1. Check security group rule
aws ec2 describe-security-groups --group-ids <RDS_SG_ID> --region us-east-1

# 2. Test connection from Fargate task
# (SSH into task or use AWS Systems Manager Session Manager)
psql -h <RDS_ENDPOINT> -U postgres -d fargate_ecommerce

# 3. Verify Secrets Manager secret
aws secretsmanager get-secret-value \
    --secret-id fargate/database \
    --region us-east-1
```

### Secrets Manager Permission Denied
```bash
# Update ecsTaskRole with SecretsManager permissions
# Attach policy to: arn:aws:iam::247523262683:role/ecsTaskRole

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:247523262683:secret:fargate/*"
    }
  ]
}
```

---

## 📝 Next Steps (Phase 2)

1. **CodePipeline Setup** (Feb 14-20)
   - Create CodeBuild projects for each service
   - Set up GitHub webhook → CodePipeline
   - Auto-deploy on git push

2. **Stripe Integration** (Feb 14-20)
   - Complete cart service
   - Add Stripe webhook handler
   - End-to-end payment flow testing

3. **ALB + SSL Setup** (Feb 6-13)
   - Create Application Load Balancer
   - Configure target groups for each service
   - Set up SSL certificates

4. **CloudWatch + Monitoring** (Feb 14-20)
   - Dashboards for each service
   - Alarms for high error rates
   - Performance metrics collection

---

## 📞 Quick Commands

```bash
# View all running services
aws ecs list-services --cluster fargate-ecommerce --region us-east-1

# Describe a service
aws ecs describe-services \
    --cluster fargate-ecommerce \
    --services fargate-ecommerce-auth \
    --region us-east-1

# Scale service
aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-auth \
    --desired-count 2 \
    --region us-east-1

# View recent logs
aws logs tail /ecs/fargate-ecommerce-auth --since 1h --region us-east-1

# Force redeploy
aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-auth \
    --force-new-deployment \
    --region us-east-1
```

---

**Good luck with the deployment! 🚀**
