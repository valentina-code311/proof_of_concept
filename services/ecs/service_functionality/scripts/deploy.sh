#!/bin/bash
set -e

#####################################
# This script deploys and tears down services on AWS ECS.
# It uses Terraform to manage infrastructure and Docker to build and push images.
# Main functions:
# - Up: Brings up the services, creates an S3 bucket, deploys infrastructure with Terraform,
#       builds and pushes a Docker image to ECR, and creates an ECS service.
# - Down: Tears down the services and destroys the infrastructure with Terraform.
########################################

# Function to display usage
Usage() {
    echo "Usage: $0 {up|down}"
    exit 1
}


# Function to bring services up
Up() {
    echo "Bringing services up..."

    # Create a bucket for the Terraform backend before deploying IaC
    aws s3api head-bucket --bucket $SERVICE_HYPHEN --region $REGION > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        aws s3api create-bucket --bucket $SERVICE_HYPHEN --region $REGION
    fi

    # Deploy Infrastructure
    ./scripts/connect.sh -s iac -u "terraform init && terraform apply --auto-approve"

    # Log in to ECR
    aws ecr get-login-password \
        --region $REGION | \
    docker login \
        --username AWS \
        --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

    # Build and tag the Docker image
    docker build \
        -f ./app/Dockerfile \
        -t $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${SERVICE}_repo:latest \
        app

    # Push Docker image to AWS
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${SERVICE}_repo:latest

    # Get security group id
    SG_ID=$(aws ec2 describe-security-groups \
        --group-name ${SERVICE}_sg \
        --query SecurityGroups[0].GroupId \
        --output text)

    # Get Subnetworks
    SUBNETS_IDS=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[].SubnetId" \
        --output text \
        --output json | jq -r 'join(",")')

    # Get Target Group ARN
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
        --names "${SERVICE_HYPHEN}-tg" \
        --query "TargetGroups[0].TargetGroupArn" \
        --output text)

    # Verify if the ECS service already exists
    aws ecs describe-services \
        --cluster ${SERVICE}_cluster \
        --services ${SERVICE}_service \
        --query "services[0].serviceArn" \
        --output text | grep -q "${SERVICE}_service"

    # Create or update ECS service
    if [ $? -eq 0 ]; then
        echo "Updating ECS service..."
        aws ecs update-service \
            --cluster ${SERVICE}_cluster \
            --service ${SERVICE}_service \
            --task-definition ${SERVICE}_task \
            --region $REGION \
            --query "service.serviceArn" \
            --output text
    fi
}

# Function to bring services down
Down() {
    echo "Bringing services down..."

    # Destroy Infrastructure
    ./scripts/connect.sh -s iac -u "terraform init && terraform destroy --auto-approve"
}

# Load environment variables
set -a; . ./conn/aws; set +a # Load aws credentials
. .env # Load general environment variables

# Set variables
REGION=$AWS_DEFAULT_REGION
VPC_ID=$TF_VAR_aws_vpc_id
SERVICE=$TF_VAR_aws_base_name
SERVICE_HYPHEN=$(echo $SERVICE | tr '_' '-')

# Get AWS account ID
AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`

# Main script logic
case "$1" in
    up) Up ;;
    down) Down ;;
    *) Usage ;;
esac
