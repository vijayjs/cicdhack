# RDS Module - MySQL Free Tier

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t2.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "db_password" {
  type      = string
  default   = "ChangeThisPassword123!"
  sensitive = true
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet"
  }
}

# RDS Instance (Free Tier)
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  
  # Storage (Free Tier: 20GB)
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 20
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database
  db_name  = "symfony_app"
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  multi_az               = false  # Free Tier

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring
  performance_insights_enabled = false  # Not available on t2.micro

  # Other settings
  skip_final_snapshot     = true
  deletion_protection     = false
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}

# Outputs
output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_port" {
  value = aws_db_instance.main.port
}
