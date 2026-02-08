#!/bin/bash
# QUICK START: Auth Deploy + RDS in 3 Steps
# Run this to get 4th microservice to Fargate by Boss Day (Feb 13)

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Fargate Ecommerce Phase 1 Quickstart${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS credentials (Account: $ACCOUNT_ID)${NC}"

echo ""
echo -e "${YELLOW}📋 Phase 1: Auth Service Deployment${NC}"
echo ""
echo "Step 1: Deploy Auth to Fargate"
echo "Run: ./scripts/deploy-auth.sh"
echo ""
echo -e "${BLUE}This will:${NC}"
echo "  • Build auth service Docker image"
echo "  • Push to ECR (247523262683.dkr.ecr.us-east-1.amazonaws.com)"
echo "  • Create task definition (fargate-ecommerce-auth)"
echo "  • Deploy to ECS cluster"
echo "  • Set up CloudWatch logging"
echo ""

read -p "Ready to deploy auth service? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    chmod +x scripts/deploy-auth.sh
    ./scripts/deploy-auth.sh
    echo -e "${GREEN}✓ Auth service deployed!${NC}"
else
    echo "Skipped auth deployment"
fi

echo ""
echo -e "${YELLOW}📋 Phase 1B: RDS PostgreSQL Setup${NC}"
echo ""
echo "Step 2: Provision RDS Database"
echo ""
echo -e "${BLUE}Prerequisites:${NC}"
echo "  • VPC Security Group ID (for Fargate tasks)"
echo "  • RDS Subnet Group (or use 'default')"
echo ""

read -p "What is your Fargate security group ID? (sg-xxxxxxxx): " VPC_SG_ID

if [ -z "$VPC_SG_ID" ]; then
    echo -e "${RED}✗ Security group ID required${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}This will create:${NC}"
echo "  • RDS PostgreSQL 15.4 instance (db.t4g.micro)"
echo "  • Database: fargate_ecommerce"
echo "  • Credentials stored in AWS Secrets Manager (fargate/database)"
echo "  • 7-day backups enabled"
echo "  • CloudWatch log export enabled"
echo ""
echo -e "${YELLOW}⏳ Note: Creation takes 5-10 minutes${NC}"
echo ""

read -p "Ready to provision RDS? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    export VPC_SG_ID="$VPC_SG_ID"
    chmod +x scripts/provision-rds.sh
    ./scripts/provision-rds.sh
    echo -e "${GREEN}✓ RDS provisioned!${NC}"
else
    echo "Skipped RDS provisioning"
fi

echo ""
echo -e "${YELLOW}📋 Phase 1C: Deploy Products + Orders with RDS${NC}"
echo ""
echo "Step 3: Connect Services to Database"
echo ""
read -p "Ready to deploy products & orders with RDS? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Registering products task definition...${NC}"
    aws ecs register-task-definition \
        --cli-input-json file://infrastructure/ecs/products-task-def.json \
        --region us-east-1 > /dev/null
    echo -e "${GREEN}✓ Registered${NC}"
    
    echo -e "${BLUE}Updating products service...${NC}"
    aws ecs update-service \
        --cluster fargate-ecommerce \
        --service fargate-ecommerce-products \
        --task-definition fargate-ecommerce-products:2 \
        --force-new-deployment \
        --region us-east-1 > /dev/null
    echo -e "${GREEN}✓ Updated${NC}"
    
    echo -e "${BLUE}Registering orders task definition...${NC}"
    aws ecs register-task-definition \
        --cli-input-json file://infrastructure/ecs/orders-task-def.json \
        --region us-east-1 > /dev/null
    echo -e "${GREEN}✓ Registered${NC}"
    
    echo -e "${BLUE}Updating orders service...${NC}"
    aws ecs update-service \
        --cluster fargate-ecommerce \
        --service fargate-ecommerce-orders \
        --task-definition fargate-ecommerce-orders:2 \
        --force-new-deployment \
        --region us-east-1 > /dev/null
    echo -e "${GREEN}✓ Updated${NC}"
else
    echo "Skipped products/orders deployment"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Phase 1 Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}📊 Your Fargate Platform:${NC}"
echo "  • Auth Service: fargate-ecommerce-auth (LIVE)"
echo "  • Products Service: fargate-ecommerce-products (LIVE + RDS)"
echo "  • Orders Service: fargate-ecommerce-orders (LIVE + RDS)"
echo "  • Cart Service: fargate-ecommerce-cart (LIVE + Stripe)"
echo ""
echo -e "${BLUE}🔗 View Logs:${NC}"
echo "  aws logs tail /ecs/fargate-ecommerce-auth --follow --region us-east-1"
echo "  aws logs tail /ecs/fargate-ecommerce-products --follow --region us-east-1"
echo "  aws logs tail /ecs/fargate-ecommerce-orders --follow --region us-east-1"
echo ""
echo -e "${BLUE}📈 Check Service Status:${NC}"
echo "  aws ecs describe-services --cluster fargate-ecommerce \\
      --services fargate-ecommerce-auth \\
      --region us-east-1 --output table"
echo ""
echo -e "${BLUE}📋 Next Steps (Phase 2 - Feb 14-20):${NC}"
echo "  1. CodePipeline: Auto-deploy on git push"
echo "  2. ALB: Load balancer + SSL"
echo "  3. Stripe: Complete end-to-end flow"
echo "  4. Monitoring: CloudWatch dashboards"
echo ""
echo -e "${BLUE}📖 Read More:${NC}"
echo "  • Deployment Guide: DEPLOYMENT_GUIDE.md"
echo "  • Infrastructure Reference: INFRASTRUCTURE.md"
echo "  • Phase 1 Status: PHASE1_STATUS.md"
echo ""
