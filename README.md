# 🚀 Symfony AWS Blue/Green Deployment

A production-ready PHP Symfony application with AWS Free Tier deployment using Terraform, blue/green deployment strategy, and complete CI/CD pipeline with security scanning.

## 📋 Features

- ✅ **PHP Symfony 7.0** - Modern PHP framework
- ✅ **AWS Free Tier** - EC2, RDS, ALB deployment
- ✅ **Blue/Green Deployment** - Zero-downtime releases
- ✅ **GitFlow CI/CD** - Automated pipeline with GitHub Actions
- ✅ **Security Scanning** - SAST, dependency, and container scanning
- ✅ **Infrastructure as Code** - Complete Terraform automation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Route 53                              ││
│  └──────────────────────┬──────────────────────────────────┘│
│                         │                                    │
│  ┌──────────────────────▼──────────────────────────────────┐│
│  │          Application Load Balancer                       ││
│  │       (Weighted Traffic Routing)                         ││
│  └────────────┬──────────────────────┬─────────────────────┘│
│               │                      │                       │
│    ┌──────────▼──────────┐ ┌────────▼───────────┐          │
│    │   BLUE Environment  │ │  GREEN Environment │          │
│    │   ┌──────────────┐  │ │  ┌──────────────┐  │          │
│    │   │   EC2 (t2)   │  │ │  │   EC2 (t2)   │  │          │
│    │   │   Symfony    │  │ │  │   Symfony    │  │          │
│    │   └──────────────┘  │ │  └──────────────┘  │          │
│    └─────────────────────┘ └────────────────────┘          │
│                         │                                    │
│    ┌────────────────────▼───────────────────────┐          │
│    │           RDS MySQL (Free Tier)             │          │
│    │              db.t2.micro                    │          │
│    └────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- PHP 8.2+
- Composer
- Docker & Docker Compose
- AWS CLI configured
- Terraform 1.5+

### Local Development
```bash
# Install dependencies
composer install

# Start Docker services
docker-compose up -d

# Run migrations
php bin/console doctrine:migrations:migrate

# Start dev server
symfony server:start
```

### Deploy to AWS
```bash
cd terraform

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Deploy application
./scripts/deploy.sh
```

## 📁 Project Structure

```
├── src/                    # Symfony application source
├── config/                 # Symfony configuration
├── templates/              # Twig templates
├── public/                 # Web root
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Terraform modules
│   │   ├── vpc/            # VPC configuration
│   │   ├── ec2/            # EC2 instances
│   │   ├── rds/            # Database
│   │   └── alb/            # Load balancer
│   └── main.tf             # Main configuration
├── .github/workflows/      # CI/CD pipelines
├── docker/                 # Docker configuration
└── scripts/                # Deployment scripts
```

## 🔄 GitFlow Branching

```
main ─────────────────────────────────→ (Production)
  │
  └── develop ────────────────────────→ (Integration)
        │
        ├── feature/login ────────────→ (Feature branches)
        ├── feature/dashboard
        │
        └── release/v1.0.0 ───────────→ (Release branches)
```

## 🔒 Security Scanning

| Tool | Type | Purpose |
|------|------|---------|
| SonarQube | SAST/Quality | Code quality and security analysis |
| PHPStan | SAST | Static code analysis |
| Composer Audit | SCA | Dependency vulnerabilities |
| Trivy | Container | Docker image scanning |
| tfsec | IaC | Terraform security |

## 📊 DevOps Metrics

- **Lead Time**: < 24 hours
- **Deployment Frequency**: Daily
- **MTTR**: < 1 hour
- **Change Failure Rate**: < 5%
