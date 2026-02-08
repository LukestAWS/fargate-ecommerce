# Infrastructure Setup Reference

Complete reference for AWS infrastructure components needed for the Fargate ecommerce platform.

## 📋 Quick Status

| Component | Status | Notes |
|-----------|--------|-------|
| ECS Cluster | ✅ Exists | `fargate-ecommerce` |
| Auth Service | 🔄 Ready to deploy | Task def created, needs ECR push |
| Products Service | ✅ Ready | Updated with RDS integration |
| Orders Service | ✅ Ready | Updated with RDS integration |
| Cart Service | ✅ Ready | Stripe integration enabled |
| RDS Postgres | 🔄 Ready to provision | Provisioning script ready |
| ALB | ❌ Not started | Phase 2 (Feb 6-13) |
| CodePipeline | ❌ Not started | Phase 2 (Feb 14-20) |

---

## 🏗️ AWS Resources Overview

### 1. ECS Cluster: `fargate-ecommerce`

Located in: **us-east-1** (N. Virginia)

```bash
# View cluster
aws ecs describe-clusters --clusters fargate-ecommerce --region us-east-1

# List services
aws ecs list-services --cluster fargate-ecommerce --region us-east-1

# View cluster capacity
aws ecs describe-clusters --clusters fargate-ecommerce --region us-east-1 \
    --include ATTACHMENTS
```

### 2. ECR Repositories

Account ID: **247523262683**

**Existing repositories**:
```
247523262683.dkr.ecr.us-east-1.amazonaws.com/
├── fargate-ecommerce-products:latest
├── fargate-ecommerce-cart:latest (with Stripe keys)
└── fargate-ecommerce-orders:latest

New (to create):
└── fargate-ecommerce-auth:latest
```

**Operations**:
```bash
# List all repositories
aws ecr describe-repositories --region us-east-1

# View images in a repo
aws ecr describe-images --repository-name fargate-ecommerce-auth --region us-east-1

# Delete image
aws ecr batch-delete-image \
    --repository-name fargate-ecommerce-auth \
    --image-ids imageTag=old-version \
    --region us-east-1
```

### 3. ECS Task Definitions

**Location**: `infrastructure/ecs/`

| File | Family | Status |
|------|--------|--------|
| auth-task-def.json | `fargate-ecommerce-auth` | ✅ Ready |
| products-task-def.json | `fargate-ecommerce-products` | ✅ Updated for RDS |
| orders-task-def.json | `fargate-ecommerce-orders` | ✅ Updated for RDS |
| cart-task-def.json | `fargate-ecommerce-cart` | ✅ With Stripe secrets |

**Key configurations**:
- Network Mode: `awsvpc` (required for Fargate)
- Platform: `FARGATE`
- CPU: `512` (0.25 vCPU)
- Memory: `1024` (1 GB)
- Container Port: `8000`

**Register/Update task definition**:
```bash
aws ecs register-task-definition \
    --cli-input-json file://infrastructure/ecs/auth-task-def.json \
    --region us-east-1

# View all task definition revisions
aws ecs list-task-definitions --family-prefix fargate-ecommerce-auth --region us-east-1

# Describe specific revision
aws ecs describe-task-definition \
    --task-definition fargate-ecommerce-auth:1 \
    --region us-east-1
```

### 4. ECS Services

**Create new service**:
```bash
aws ecs create-service \
    --cluster fargate-ecommerce \
    --service-name fargate-ecommerce-auth \
    --task-definition fargate-ecommerce-auth:1 \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={
        subnets=[subnet-xxx,subnet-yyy],
        securityGroups=[sg-xxxxxxxx],
        assignPublicIp=ENABLED
    }" \
    --region us-east-1
```

**Update service**:
```bash
aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-auth \
    --task-definition fargate-ecommerce-auth:2 \
    --force-new-deployment \
    --region us-east-1
```

**Scale service**:
```bash
aws ecs update-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-auth \
    --desired-count 3 \
    --region us-east-1
```

### 5. IAM Roles & Policies

**ecsTaskExecutionRole**
- Purpose: Allows ECS agent to pull images, write logs, access Secrets Manager
- ARN: `arn:aws:iam::247523262683:role/ecsTaskExecutionRole`

**ecsTaskRole**
- Purpose: Allows container to call AWS APIs (S3, RDS, etc.)
- ARN: `arn:aws:iam::247523262683:role/ecsTaskRole`

**View role trust relationship**:
```bash
aws iam get-role --role-name ecsTaskExecutionRole --query 'Role.AssumeRolePolicyDocument'
```

**Attach policy to role**:
```bash
aws iam attach-role-policy \
    --role-name ecsTaskRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### 6. CloudWatch Logs

**Log groups**:
- `/ecs/fargate-ecommerce-auth` (30 days retention)
- `/ecs/fargate-ecommerce-products` (30 days)
- `/ecs/fargate-ecommerce-orders` (30 days)
- `/ecs/fargate-ecommerce-cart` (30 days)

**Create log group**:
```bash
aws logs create-log-group \
    --log-group-name /ecs/fargate-ecommerce-auth \
    --region us-east-1

aws logs put-retention-policy \
    --log-group-name /ecs/fargate-ecommerce-auth \
    --retention-in-days 30 \
    --region us-east-1
```

**View logs**:
```bash
# Stream logs in real-time
aws logs tail /ecs/fargate-ecommerce-auth --follow --region us-east-1

# View last hour
aws logs tail /ecs/fargate-ecommerce-auth --since 1h --region us-east-1

# Search for errors
aws logs filter-log-events \
    --log-group-name /ecs/fargate-ecommerce-auth \
    --filter-pattern "ERROR" \
    --region us-east-1
```

### 7. AWS Secrets Manager

**Production secrets storage**:

```bash
# Store JWT secret for auth service
aws secretsmanager create-secret \
    --name fargate/auth-keys \
    --secret-string '{"SECRET_KEY":"your-jwt-secret"}' \
    --region us-east-1

# Store database connection
aws secretsmanager create-secret \
    --name fargate/database \
    --secret-string '{
        "url":"postgresql://...",
        "username":"postgres",
        "password":"...",
        "host":"...",
        "port":5432,
        "database":"fargate_ecommerce"
    }' \
    --region us-east-1

# Store Stripe keys
aws secretsmanager create-secret \
    --name fargate/stripe-keys \
    --secret-string '{
        "STRIPE_SECRET_KEY":"sk_live_...",
        "STRIPE_PUBLISHABLE_KEY":"pk_live_..."
    }' \
    --region us-east-1

# Retrieve secret
aws secretsmanager get-secret-value \
    --secret-id fargate/database \
    --region us-east-1

# Update secret
aws secretsmanager update-secret \
    --secret-id fargate/database \
    --secret-string '{...}' \
    --region us-east-1
```

**Reference in task definition**:
```json
"secrets": [
  {
    "name": "DATABASE_URL",
    "valueFrom": "arn:aws:secretsmanager:us-east-1:247523262683:secret:fargate/database:url::"
  }
]
```

### 8. VPC & Security Groups

**Required for Fargate**:
- VPC with public/private subnets
- Security group for Fargate tasks
- Security group for RDS (if using)
- NAT gateway for private subnet outbound traffic

**View VPC resources**:
```bash
# List VPCs
aws ec2 describe-vpcs --region us-east-1

# List subnets
aws ec2 describe-subnets --region us-east-1

# List security groups
aws ec2 describe-security-groups --region us-east-1

# View security group rules
aws ec2 describe-security-groups \
    --group-ids sg-xxxxxxxx \
    --region us-east-1
```

**Create security group for RDS access**:
```bash
# Allow Fargate → RDS on port 5432
aws ec2 authorize-security-group-ingress \
    --group-id sg-rds-xxxx \
    --protocol tcp \
    --port 5432 \
    --source-group sg-fargate-xxxx \
    --region us-east-1
```

---

## 🗄️ RDS Setup (Phase 1)

### Create Postgres Instance

```bash
aws rds create-db-instance \
    --db-instance-identifier fargate-db \
    --db-instance-class db.t4g.micro \
    --engine postgres \
    --engine-version 15.4 \
    --master-username postgres \
    --master-user-password '<random-32-char-password>' \
    --allocated-storage 20 \
    --storage-type gp3 \
    --publicly-accessible false \
    --multi-az false \
    --db-name fargate_ecommerce \
    --port 5432 \
    --vpc-security-group-ids sg-xxxxxxxx \
    --db-subnet-group-name default \
    --backup-retention-period 7 \
    --enable-cloudwatch-logs-exports '["postgresql"]' \
    --region us-east-1
```

### Check Status

```bash
# Wait for available
aws rds wait db-instance-available \
    --db-instance-identifier fargate-db \
    --region us-east-1

# Get endpoint
aws rds describe-db-instances \
    --db-instance-identifier fargate-db \
    --region us-east-1 \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
```

### Connect from Local

```bash
# Install psql
# Ubuntu: sudo apt-get install postgresql-client
# macOS: brew install postgresql

# Connect
psql -h fargate-db.xxxxxxxxx.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d fargate_ecommerce

# Run migrations (if using Alembic, etc.)
```

---

## ⚙️ Deployment Scripts

### `deploy-auth.sh`
- Builds auth service Docker image
- Pushes to ECR
- Registers task definition
- Creates/updates ECS service
- Sets up CloudWatch logging

### `provision-rds.sh`
- Creates RDS Postgres instance
- Stores credentials in Secrets Manager
- Generates environment files
- Outputs connection string

### Manual Cleanup

```bash
# Delete auth ECS service
aws ecs delete-service \
    --cluster fargate-ecommerce \
    --service fargate-ecommerce-auth \
    --force \
    --region us-east-1

# Deregister task definitions
aws ecs deregister-task-definition \
    --task-definition fargate-ecommerce-auth:1 \
    --region us-east-1

# Delete RDS instance
aws rds delete-db-instance \
    --db-instance-identifier fargate-db \
    --skip-final-snapshot \
    --region us-east-1

# Delete ECR repository
aws ecr delete-repository \
    --repository-name fargate-ecommerce-auth \
    --force \
    --region us-east-1

# Delete Secrets
aws secretsmanager delete-secret \
    --secret-id fargate/database \
    --force-delete-without-recovery \
    --region us-east-1
```

---

## 🔍 Monitoring & Debugging

### View Service Metrics

```bash
# ECS service metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=fargate-ecommerce-auth Name=ClusterName,Value=fargate-ecommerce \
    --statistics Average,Maximum \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --region us-east-1
```

### List Running Tasks

```bash
# List tasks
aws ecs list-tasks --cluster fargate-ecommerce --region us-east-1

# Describe task
aws ecs describe-tasks \
    --cluster fargate-ecommerce \
    --tasks arn:aws:ecs:us-east-1:247523262683:task/... \
    --region us-east-1
```

### Get Task IP & Port

```bash
# Get task details
aws ecs describe-tasks \
    --cluster fargate-ecommerce \
    --tasks arn:aws:ecs:us-east-1:247523262683:task/... \
    --region us-east-1 \
    --query 'tasks[0].networkInterfaces[0].privateIpv4Address'
```

---

## 📝 Environment Variables & Secrets

### Auth Service
```
PYTHONUNBUFFERED=1
```

### Products Service
```
PYTHONUNBUFFERED=1
DATABASE_URL=postgresql://postgres:password@fargate-db.xxx.rds.amazonaws.com:5432/fargate_ecommerce
```

### Orders Service
```
PYTHONUNBUFFERED=1
DATABASE_URL=postgresql://postgres:password@fargate-db.xxx.rds.amazonaws.com:5432/fargate_ecommerce
```

### Cart Service
```
PYTHONUNBUFFERED=1
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
```

---

## 🚀 Phase 2: ALB Setup (Feb 6-13)

```bash
# Create ALB
aws elbv2 create-load-balancer \
    --name fargate-alb \
    --subnets subnet-xxxx subnet-yyyy \
    --security-groups sg-xxxxxxxx \
    --scheme internet-facing \
    --type application \
    --region us-east-1

# Create target group for auth
aws elbv2 create-target-group \
    --name fargate-auth-tg \
    --protocol HTTP \
    --port 8000 \
    --vpc-id vpc-xxxxxxxx \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --region us-east-1

# Register targets (auto-populated by ECS service)
# With ECS service integration, this happens automatically

# Create listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:... \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:... \
    --region us-east-1
```

---

## 📊 Cost Estimate (Monthly)

| Resource | Size | Monthly |
|----------|------|---------|
| ECS Fargate (4 tasks × 512 CPU) | 2 vCPU | ~$30 |
| Fargate Memory (4 tasks × 1GB) | 4 GB | ~$0.04 |
| ALB | 1x | ~$20 |
| RDS db.t4g.micro | 1x | ~$35 |
| NAT Gateway | 1x | ~$32 |
| Data Transfer | ~10 GB | ~$1 |
| **TOTAL** | | **~$120/month** |

*Prices are estimates and may vary. Use AWS Pricing Calculator for exact quotes.*

---

## 📞 Useful AWS CLI Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias awsp='export AWS_PROFILE=default && export AWS_REGION=us-east-1'
alias ecs-services='aws ecs list-services --cluster fargate-ecommerce --region us-east-1'
alias ecs-tasks='aws ecs list-tasks --cluster fargate-ecommerce --region us-east-1'
alias ecs-logs-auth='aws logs tail /ecs/fargate-ecommerce-auth --follow --region us-east-1'
alias rds-status='aws rds describe-db-instances --db-instance-identifier fargate-db --region us-east-1 --query "DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]" --output table'
```

---

**Last Updated**: February 2026
**Phase**: 1 (Auth Deploy + RDS)
**Next**: Phase 2 (ALB + CodePipeline)
