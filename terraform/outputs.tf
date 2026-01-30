# Terraform Outputs

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "blue_environment" {
  description = "Blue environment details"
  value = {
    instance_id = module.blue.instance_id
    public_ip   = module.blue.public_ip
    version     = var.blue_version
    traffic     = "${var.blue_traffic_weight}%"
  }
}

output "green_environment" {
  description = "Green environment details"
  value = {
    instance_id = module.green.instance_id
    public_ip   = module.green.public_ip
    version     = var.green_version
    traffic     = "${var.green_traffic_weight}%"
  }
}

output "database" {
  description = "Database connection info"
  value = {
    endpoint = module.rds.db_endpoint
    name     = module.rds.db_name
    port     = module.rds.db_port
  }
  sensitive = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "traffic_distribution" {
  description = "Current traffic distribution"
  value = {
    blue  = "${var.blue_traffic_weight}%"
    green = "${var.green_traffic_weight}%"
  }
}

output "active_environment" {
  description = "Currently active environment"
  value       = var.blue_traffic_weight > var.green_traffic_weight ? "blue" : "green"
}
