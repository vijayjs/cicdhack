# Terraform Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "symfony-bg"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "blue_version" {
  description = "Application version for Blue environment"
  type        = string
  default     = "v1.0.0"
}

variable "green_version" {
  description = "Application version for Green environment"
  type        = string
  default     = "v1.0.0"
}

variable "blue_traffic_weight" {
  description = "Traffic weight for Blue environment (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.blue_traffic_weight >= 0 && var.blue_traffic_weight <= 100
    error_message = "Traffic weight must be between 0 and 100."
  }
}

variable "green_traffic_weight" {
  description = "Traffic weight for Green environment (0-100)"
  type        = number
  default     = 0

  validation {
    condition     = var.green_traffic_weight >= 0 && var.green_traffic_weight <= 100
    error_message = "Traffic weight must be between 0 and 100."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of AWS key pair for EC2 SSH access"
  type        = string
  default     = "symfony-key"
}
