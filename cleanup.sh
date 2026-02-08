#!/bin/bash
echo "🛑 Starting Nuclear Cleanup..."

# 1. Delete the ALB (The $0.02/hr silent killer)
# Replace with your actual ALB Name if you create one
ALB_ARN=$(aws elbv2 describe-load-balancers --names "fargate-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
if [ ! -z "$ALB_ARN" ]; then
    aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
    echo "✅ ALB Deleted"
fi

# 2. Delete RDS (Skip snapshot to avoid storage fees)
aws rds delete-db-instance --db-instance-identifier "fargate-db" --skip-final-snapshot 2>/dev/null
echo "✅ RDS Deletion Triggered"

# 3. Delete ElastiCache
aws elasticache delete-cache-cluster --cache-cluster-id "fargate-redis" 2>/dev/null
echo "✅ Redis Deletion Triggered"
