#!/bin/bash
# Health Check Script
# Usage: ./health-check.sh [environment]

set -e

ENVIRONMENT=${1:-all}
AWS_REGION=${AWS_REGION:-us-east-1}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_instance() {
    local env=$1
    local ip=$2
    
    echo -e "${BLUE}Checking $env environment ($ip)...${NC}"
    
    # Health endpoint
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$ip/health" --connect-timeout 5 || echo "000")
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "  Health:    ${GREEN}✅ Healthy${NC}"
    else
        echo -e "  Health:    ${RED}❌ Unhealthy (HTTP $HTTP_CODE)${NC}"
    fi
    
    # Response time
    RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "http://$ip/" --connect-timeout 5 || echo "N/A")
    echo "  Response:  ${RESPONSE_TIME}s"
    
    # Get version
    VERSION=$(curl -s "http://$ip/api/deployment/status" 2>/dev/null | jq -r '.version' 2>/dev/null || echo "N/A")
    echo "  Version:   $VERSION"
    
    echo ""
}

get_instance_ip() {
    local env=$1
    aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=$env" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text \
        --region $AWS_REGION 2>/dev/null || echo "N/A"
}

echo -e "${BLUE}=== Health Check ===${NC}"
echo ""

if [ "$ENVIRONMENT" == "all" ] || [ "$ENVIRONMENT" == "blue" ]; then
    BLUE_IP=$(get_instance_ip "blue")
    if [ "$BLUE_IP" != "None" ] && [ "$BLUE_IP" != "N/A" ]; then
        check_instance "BLUE" $BLUE_IP
    else
        echo -e "${YELLOW}Blue environment not found${NC}"
        echo ""
    fi
fi

if [ "$ENVIRONMENT" == "all" ] || [ "$ENVIRONMENT" == "green" ]; then
    GREEN_IP=$(get_instance_ip "green")
    if [ "$GREEN_IP" != "None" ] && [ "$GREEN_IP" != "N/A" ]; then
        check_instance "GREEN" $GREEN_IP
    else
        echo -e "${YELLOW}Green environment not found${NC}"
        echo ""
    fi
fi

# Check ALB
echo -e "${BLUE}Checking Load Balancer...${NC}"
cd "$(dirname "$0")/../terraform"
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")

if [ "$ALB_DNS" != "N/A" ]; then
    ALB_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/health" --connect-timeout 5 || echo "000")
    if [ "$ALB_CODE" == "200" ]; then
        echo -e "  ALB:       ${GREEN}✅ Healthy${NC}"
    else
        echo -e "  ALB:       ${RED}❌ Unhealthy (HTTP $ALB_CODE)${NC}"
    fi
    echo "  DNS:       $ALB_DNS"
else
    echo -e "  ALB:       ${YELLOW}Not configured${NC}"
fi

echo ""
echo "Check completed at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
