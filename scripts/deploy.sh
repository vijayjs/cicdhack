#!/bin/bash
# Blue/Green Deployment Script
# Usage: ./deploy.sh [blue|green] [version]

set -e

ENVIRONMENT=${1:-green}
VERSION=${2:-$(git describe --tags --always)}
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_NAME="symfony-bg"

echo "🚀 Deploying version $VERSION to $ENVIRONMENT environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get instance ID
get_instance_id() {
    local env=$1
    aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=$env" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --region $AWS_REGION
}

# Function to check instance health
check_health() {
    local instance_id=$1
    local ip=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text \
        --region $AWS_REGION)
    
    echo "Checking health at http://$ip/health"
    
    for i in {1..30}; do
        if curl -s -o /dev/null -w "%{http_code}" "http://$ip/health" | grep -q "200"; then
            echo -e "${GREEN}✅ Health check passed${NC}"
            return 0
        fi
        echo "Attempt $i/30 - waiting..."
        sleep 10
    done
    
    echo -e "${RED}❌ Health check failed${NC}"
    return 1
}

# Function to deploy application
deploy_app() {
    local instance_id=$1
    local version=$2
    
    echo "📦 Packaging application..."
    tar -czf /tmp/app.tar.gz \
        --exclude='.git' \
        --exclude='terraform' \
        --exclude='node_modules' \
        --exclude='var/cache' \
        --exclude='var/log' \
        .
    
    echo "⬆️ Uploading to S3..."
    aws s3 cp /tmp/app.tar.gz s3://${PROJECT_NAME}-deployments/app-${version}.tar.gz --region $AWS_REGION
    
    echo "🔧 Deploying to instance $instance_id..."
    aws ssm send-command \
        --instance-ids $instance_id \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[
            'cd /var/www/html',
            'aws s3 cp s3://${PROJECT_NAME}-deployments/app-${version}.tar.gz /tmp/',
            'rm -rf /var/www/html/*',
            'tar -xzf /tmp/app-${version}.tar.gz -C /var/www/html',
            'cd /var/www/html && composer install --no-dev --optimize-autoloader',
            'php bin/console cache:clear --env=prod',
            'chown -R apache:apache /var/www/html',
            'systemctl restart httpd'
        ]" \
        --timeout-seconds 600 \
        --region $AWS_REGION
    
    echo "⏳ Waiting for deployment to complete..."
    sleep 60
}

# Main deployment flow
main() {
    echo -e "${BLUE}=== Blue/Green Deployment ===${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Version: $VERSION"
    echo ""
    
    # Get instance ID
    INSTANCE_ID=$(get_instance_id $ENVIRONMENT)
    
    if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
        echo -e "${RED}❌ No running instance found for $ENVIRONMENT environment${NC}"
        exit 1
    fi
    
    echo "Instance ID: $INSTANCE_ID"
    
    # Deploy application
    deploy_app $INSTANCE_ID $VERSION
    
    # Health check
    if check_health $INSTANCE_ID; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Run smoke tests"
        echo "  2. Switch traffic using: ./switch-traffic.sh $ENVIRONMENT"
    else
        echo -e "${RED}❌ Deployment failed - instance not healthy${NC}"
        exit 1
    fi
}

main
