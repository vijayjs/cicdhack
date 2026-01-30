# Terraform Main Configuration
# AWS Blue/Green Deployment for Symfony Application

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "symfony-terraform-state"
    key            = "bluegreen/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "symfony-bluegreen"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# Security Groups Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# RDS Database Module (Free Tier)
module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
  
  db_instance_class   = "db.t2.micro"  # Free Tier
  db_allocated_storage = 20             # Free Tier limit
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# Blue Environment
module "blue" {
  source = "./modules/ec2"

  project_name       = var.project_name
  environment        = "blue"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  ec2_security_group_id = module.security.ec2_security_group_id
  target_group_arn   = module.alb.blue_target_group_arn
  
  instance_type      = "t2.micro"  # Free Tier
  app_version        = var.blue_version
  db_host            = module.rds.db_endpoint
  db_name            = module.rds.db_name
}

# Green Environment
module "green" {
  source = "./modules/ec2"

  project_name       = var.project_name
  environment        = "green"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  ec2_security_group_id = module.security.ec2_security_group_id
  target_group_arn   = module.alb.green_target_group_arn
  
  instance_type      = "t2.micro"  # Free Tier
  app_version        = var.green_version
  db_host            = module.rds.db_endpoint
  db_name            = module.rds.db_name
}

# Blue/Green Traffic Switching
resource "aws_lb_listener_rule" "blue_green" {
  listener_arn = module.alb.listener_arn
  priority     = 100

  action {
    type = "forward"

    forward {
      target_group {
        arn    = module.alb.blue_target_group_arn
        weight = var.blue_traffic_weight
      }

      target_group {
        arn    = module.alb.green_target_group_arn
        weight = var.green_traffic_weight
      }

      stickiness {
        enabled  = true
        duration = 300
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "blue_instance_id" {
  description = "Blue environment EC2 instance ID"
  value       = module.blue.instance_id
}

output "green_instance_id" {
  description = "Green environment EC2 instance ID"
  value       = module.green.instance_id
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "active_environment" {
  description = "Current active environment based on traffic weight"
  value       = var.blue_traffic_weight > var.green_traffic_weight ? "blue" : "green"
}
