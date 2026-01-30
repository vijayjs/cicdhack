# Disaster Recovery Module
# Configures cross-region replication and failover capabilities

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "dr_region" {
  type    = string
  default = "us-west-2"
}

variable "enable_dr" {
  type    = bool
  default = false
}

variable "primary_db_arn" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type = string
}

# S3 Bucket for DR backups with cross-region replication
resource "aws_s3_bucket" "dr_backup" {
  bucket = "${var.project_name}-dr-backup-${var.environment}"

  tags = {
    Name        = "${var.project_name}-dr-backup"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}

resource "aws_s3_bucket_versioning" "dr_backup" {
  bucket = aws_s3_bucket.dr_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dr_backup" {
  bucket = aws_s3_bucket.dr_backup.id

  rule {
    id     = "cleanup-old-backups"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# SNS Topic for DR alerts
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.project_name}-dr-alerts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-dr-alerts"
    Environment = var.environment
  }
}

# CloudWatch Alarms for DR monitoring
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is too high"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-db-${var.environment}"
  }

  tags = {
    Name        = "${var.project_name}-rds-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High 5XX error rate detected"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]

  tags = {
    Name        = "${var.project_name}-5xx-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Unhealthy hosts detected behind ALB"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.dr_alerts.arn]

  tags = {
    Name        = "${var.project_name}-unhealthy-alarm"
    Environment = var.environment
  }
}

# Lambda for automated failover (stub)
resource "aws_iam_role" "dr_lambda_role" {
  name = "${var.project_name}-dr-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-dr-lambda-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "dr_lambda_policy" {
  name = "${var.project_name}-dr-lambda-policy"
  role = aws_iam_role.dr_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:PromoteReadReplica",
          "ec2:DescribeInstances",
          "elasticloadbalancing:*",
          "route53:*",
          "sns:Publish",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "dr_backup_bucket" {
  value = aws_s3_bucket.dr_backup.bucket
}

output "dr_alerts_topic_arn" {
  value = aws_sns_topic.dr_alerts.arn
}

output "dr_lambda_role_arn" {
  value = aws_iam_role.dr_lambda_role.arn
}
