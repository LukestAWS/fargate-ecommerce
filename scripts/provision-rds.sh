#!/bin/bash

# RDS Postgres Provisioning Script
# Creates PostgreSQL instance and updates service environment variables

set -e

# Configuration
AWS_ACCOUNT_ID="247523262683"
AWS_REGION="us-east-1"
DB_INSTANCE_ID="fargate-db"
DB_NAME="fargate_ecommerce"
DB_USER="postgres"
DB_PASSWORD="${DB_PASSWORD:-$(openssl rand -base64 32)}"
DB_PORT="5432"
DB_INSTANCE_CLASS="db.t4g.micro"
DB_ALLOCATED_STORAGE="20"
VPC_SG_ID="${VPC_SG_ID:-sg-xxxxxxxx}"  # Update with your security group
DB_SUBNET_GROUP="${DB_SUBNET_GROUP:-default}"

echo "🗄️  RDS Postgres Provisioning"
echo "================================"
echo "Instance ID: $DB_INSTANCE_ID"
echo "Region: $AWS_REGION"
echo "Database: $DB_NAME"
echo ""

# Step 1: Check if RDS instance already exists
echo "🔍 Checking if RDS instance exists..."
if aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" &>/dev/null; then
    echo "   ✓ RDS instance already exists"
    # Get the endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
else
    echo "   Creating new RDS instance..."
    
    # Create RDS instance
    aws rds create-db-instance \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --db-instance-class "$DB_INSTANCE_CLASS" \
        --engine postgres \
        --engine-version "15.4" \
        --master-username "$DB_USER" \
        --master-user-password "$DB_PASSWORD" \
        --allocated-storage "$DB_ALLOCATED_STORAGE" \
        --storage-type "gp3" \
        --publicly-accessible false \
        --multi-az false \
        --db-name "$DB_NAME" \
        --port "$DB_PORT" \
        --vpc-security-group-ids "$VPC_SG_ID" \
        --db-subnet-group-name "$DB_SUBNET_GROUP" \
        --backup-retention-period 7 \
        --enable-cloudwatch-logs-exports '["postgresql"]' \
        --region "$AWS_REGION"
    
    echo "   ✓ RDS instance creation initiated"
    echo ""
    echo "⏳ Waiting for RDS instance to be available (this may take 5-10 minutes)..."
    
    aws rds wait db-instance-available \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --region "$AWS_REGION"
    
    echo "   ✓ RDS instance is now available"
    
    # Get the endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
fi

echo ""
echo "📝 RDS Instance Details:"
echo "   Endpoint: $ENDPOINT:$DB_PORT"
echo "   Database: $DB_NAME"
echo "   Username: $DB_USER"
echo "   Region: $AWS_REGION"

# Step 2: Store credentials in Secrets Manager
echo ""
echo "🔐 Storing database credentials in AWS Secrets Manager..."

SECRET_NAME="fargate/database"
DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$ENDPOINT:$DB_PORT/$DB_NAME"

# Create or update the secret
aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Fargate ecommerce database credentials" \
    --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASSWORD\",\"host\":\"$ENDPOINT\",\"port\":$DB_PORT,\"database\":\"$DB_NAME\",\"url\":\"$DATABASE_URL\"}" \
    --region "$AWS_REGION" 2>/dev/null || \
aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASSWORD\",\"host\":\"$ENDPOINT\",\"port\":$DB_PORT,\"database\":\"$DB_NAME\",\"url\":\"$DATABASE_URL\"}" \
    --region "$AWS_REGION"

echo "   ✓ Credentials stored in: $SECRET_NAME"

# Step 3: Generate environment files
echo ""
echo "📄 Generating environment configuration files..."

# Products service env
cat > /tmp/products-env.txt <<EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$ENDPOINT:$DB_PORT/$DB_NAME
DATABASE_HOST=$ENDPOINT
DATABASE_PORT=$DB_PORT
DATABASE_NAME=$DB_NAME
DATABASE_USER=$DB_USER
EOF

# Orders service env
cat > /tmp/orders-env.txt <<EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$ENDPOINT:$DB_PORT/$DB_NAME
DATABASE_HOST=$ENDPOINT
DATABASE_PORT=$DB_PORT
DATABASE_NAME=$DB_NAME
DATABASE_USER=$DB_USER
EOF

echo "   ✓ Environment files generated:"
echo "     - /tmp/products-env.txt"
echo "     - /tmp/orders-env.txt"

echo ""
echo "✅ RDS Provisioning Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Update security group to allow Fargate tasks to access RDS"
echo "   Security Group: $VPC_SG_ID"
echo ""
echo "2. Update ECS task definitions with DATABASE_URL:"
echo "   arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$SECRET_NAME:url::"
echo ""
echo "3. Deploy or redeploy services:"
echo "   aws ecs update-service --cluster fargate-ecommerce --service fargate-ecommerce-products --force-new-deployment"
echo "   aws ecs update-service --cluster fargate-ecommerce --service fargate-ecommerce-orders --force-new-deployment"
echo ""
echo "🔗 Connection String:"
echo "   $DATABASE_URL"
