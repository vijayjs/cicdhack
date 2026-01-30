#!/bin/bash
# Switch Traffic Between Blue and Green Environments
# Usage: ./switch-traffic.sh [target_env] [weight]

set -e

TARGET_ENV=${1:-green}
WEIGHT=${2:-100}
AWS_REGION=${AWS_REGION:-us-east-1}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Traffic Switch ===${NC}"
echo "Target: $TARGET_ENV"
echo "Weight: $WEIGHT%"
echo ""

# Calculate weights
if [ "$TARGET_ENV" == "blue" ]; then
    BLUE_WEIGHT=$WEIGHT
    GREEN_WEIGHT=$((100 - WEIGHT))
else
    GREEN_WEIGHT=$WEIGHT
    BLUE_WEIGHT=$((100 - WEIGHT))
fi

echo "Blue traffic: ${BLUE_WEIGHT}%"
echo "Green traffic: ${GREEN_WEIGHT}%"
echo ""

# Confirm before proceeding
if [[ "$3" != "-y" ]]; then
    read -p "Proceed with traffic switch? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Switch traffic using Terraform
cd "$(dirname "$0")/../terraform"

echo -e "${YELLOW}🔄 Switching traffic...${NC}"

terraform init -input=false > /dev/null 2>&1

terraform apply -auto-approve \
    -var="blue_traffic_weight=$BLUE_WEIGHT" \
    -var="green_traffic_weight=$GREEN_WEIGHT" \
    -input=false

echo ""
echo -e "${GREEN}✅ Traffic switch complete!${NC}"
echo ""
echo "Current distribution:"
echo "  Blue:  ${BLUE_WEIGHT}%"
echo "  Green: ${GREEN_WEIGHT}%"

# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")
echo ""
echo "Application URL: http://$ALB_DNS"
