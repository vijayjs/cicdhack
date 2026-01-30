#!/bin/bash
# Rollback Script
# Usage: ./rollback.sh

set -e

AWS_REGION=${AWS_REGION:-us-east-1}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  ROLLBACK INITIATED${NC}"
echo ""

# Get current active environment
cd "$(dirname "$0")/../terraform"

CURRENT_BLUE=$(terraform output -raw blue_traffic_weight 2>/dev/null || echo "0")
CURRENT_GREEN=$(terraform output -raw green_traffic_weight 2>/dev/null || echo "0")

if [ "$CURRENT_BLUE" -gt "$CURRENT_GREEN" ]; then
    CURRENT_ACTIVE="blue"
    ROLLBACK_TO="green"
else
    CURRENT_ACTIVE="green"
    ROLLBACK_TO="blue"
fi

echo "Current active: $CURRENT_ACTIVE"
echo "Rolling back to: $ROLLBACK_TO"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled."
    exit 0
fi

echo -e "${YELLOW}🔄 Performing instant rollback...${NC}"

# Instant traffic switch
if [ "$ROLLBACK_TO" == "blue" ]; then
    terraform apply -auto-approve \
        -var="blue_traffic_weight=100" \
        -var="green_traffic_weight=0" \
        -input=false
else
    terraform apply -auto-approve \
        -var="blue_traffic_weight=0" \
        -var="green_traffic_weight=100" \
        -input=false
fi

echo ""
echo -e "${GREEN}✅ Rollback complete!${NC}"
echo "Traffic is now routed to: $ROLLBACK_TO"
echo ""
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
