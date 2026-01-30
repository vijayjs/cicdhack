# EC2 Module for Blue/Green Environments

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ec2_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "app_version" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# User Data Script
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    dnf update -y

    # Install required packages
    dnf install -y httpd php8.2 php8.2-fpm php8.2-mysqlnd php8.2-mbstring php8.2-xml php8.2-intl git

    # Start and enable services
    systemctl start httpd
    systemctl enable httpd
    systemctl start php-fpm
    systemctl enable php-fpm

    # Configure Apache for PHP-FPM
    cat > /etc/httpd/conf.d/php.conf << 'PHPCONF'
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
    </FilesMatch>
    DirectoryIndex index.php
    PHPCONF

    # Configure virtual host
    cat > /etc/httpd/conf.d/symfony.conf << 'VHOST'
    <VirtualHost *:80>
        DocumentRoot /var/www/html/public
        
        <Directory /var/www/html/public>
            AllowOverride All
            Require all granted
            FallbackResource /index.php
        </Directory>
        
        ErrorLog /var/log/httpd/symfony_error.log
        CustomLog /var/log/httpd/symfony_access.log combined
    </VirtualHost>
    VHOST

    # Set environment variables
    echo "export DEPLOYMENT_ENV=${var.environment}" >> /etc/profile.d/symfony.sh
    echo "export APP_VERSION=${var.app_version}" >> /etc/profile.d/symfony.sh
    echo "export DATABASE_URL=mysql://app:password@${var.db_host}/${var.db_name}" >> /etc/profile.d/symfony.sh

    # Restart Apache
    systemctl restart httpd

    # Signal completion
    echo "Setup completed for ${var.environment} environment"
  EOF
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.ec2_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  user_data = base64encode(local.user_data)

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    Environment = var.environment
    Version     = var.app_version
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Register instance with target group
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app.id
  port             = 80
}

# Outputs
output "instance_id" {
  value = aws_instance.app.id
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "private_ip" {
  value = aws_instance.app.private_ip
}
