#!/bin/bash
# Monitor Phase 1 deployment status
# Usage: bash monitor-deployment.sh

echo "🔄 Monitoring Phase 1 Deployment..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

check_services() {
    echo "${YELLOW}=== ECS Services Status ===${NC}"
    for svc in auth products orders; do
        service_name="fargate-ecommerce-$svc"
        result=$(aws ecs describe-services \
            --cluster fargate-ecommerce \
            --services "$service_name" \
            --region us-east-1 \
            --query 'services[0].[status,desiredCount,runningCount]' \
            --output text 2>/dev/null)
        
        if [ -z "$result" ]; then
            echo -e "${RED}✗${NC} $svc: Service not found"
        else
            status=$(echo "$result" | awk '{print $1}')
            desired=$(echo "$result" | awk '{print $2}')
            running=$(echo "$result" | awk '{print $3}')
            
            if [ "$running" -eq "$desired" ]; then
                echo -e "${GREEN}✓${NC} $svc: $status (running: $running/$desired)"
            else
                echo -e "${YELLOW}⏳${NC} $svc: $status (running: $running/$desired)"
            fi
        fi
    done
}

check_rds() {
    echo ""
    echo "${YELLOW}=== RDS Status ===${NC}"
    result=$(aws rds describe-db-instances \
        --db-instance-identifier fargate-db \
        --region us-east-1 \
        --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
        --output text 2>/dev/null)
    
    if [ -z "$result" ]; then
        echo -e "${RED}✗${NC} RDS: Instance not found"
    else
        status=$(echo "$result" | awk '{print $1}')
        endpoint=$(echo "$result" | awk '{print $2}')
        
        if [ "$status" = "available" ]; then
            echo -e "${GREEN}✓${NC} RDS: $status"
            echo "   Endpoint: $endpoint:5432"
        else
            echo -e "${YELLOW}⏳${NC} RDS: $status"
            echo "   Endpoint: $endpoint:5432"
        fi
    fi
}

check_logs() {
    echo ""
    echo "${YELLOW}=== Recent Logs ===${NC}"
    for svc in auth products orders; do
        log_group="/ecs/fargate-ecommerce-$svc"
        
        # Try to get recent log events
        events=$(aws logs filter-log-events \
            --log-group-name "$log_group" \
            --start-time $(date -d '1 minute ago' +%s)000 \
            --region us-east-1 \
            --query 'events[].message' \
            --output text 2>/dev/null | head -1)
        
        if [ -n "$events" ]; then
            echo -e "${GREEN}✓${NC} $svc has logs"
        else
            echo -e "${YELLOW}~${NC} $svc: No recent logs yet"
        fi
    done
}

# Main loop
iteration=1
while true; do
    clear
    echo "Phase 1 Deployment Monitor - $(date '+%H:%M:%S') [Iteration: $iteration]"
    echo "======================================================"
    echo ""
    
    check_services
    check_rds
    check_logs
    
    echo ""
    echo "${YELLOW}Press Ctrl+C to exit. Refreshing in 10 seconds...${NC}"
    sleep 10
    iteration=$((iteration + 1))
done
