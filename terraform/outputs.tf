# Artifact registry outputs
output "artifact_registry_repository" {
  description = "Artifact registry repository ID for container images"
  value = google_artifact_registry_repository.repo.repository_id
}

output "artifact_registry_repository_url" {
  description = "Full URL of the Artifact Registry repository"
  value = "${var.REGION}-docker.pkg.dev/${var.PROJECT_ID}/${google_artifact_registry_repository.repo.repository_id}"
}
# Crypto API outputs
output "crypto_api_service_url" {
  description = "Public URL  of the Crypto API Cloud Run service "
  value = google_cloud_run_v2_service.crypto_api.uri
}

output "crypto_api_service_name" {
  description = "Deployed Cloud Run service name for Crypto API"
  value = google_cloud_run_v2_service.crypto_api.name
}
# Service account outputs
output "service_account_email" {
  description = "Service account email used by cloud run services"
    value = google_service_account.crypto_api_sa.email
}

# n8n Cloud Run outputs
output "n8n_service_name" {
  description = "Deployed Cloud Run Service name for n8n"
  value = google_cloud_run_v2_service.n8n.name
}

output "n8n_service_url" {
  description = "Public URL of the n8n cloud run service"
  value = google_cloud_run_v2_service.n8n.uri
}


# Cloud SQL outputs
output "cloudsql_instance_connection_name" {
  description = "Connection name of the cloud SQL Postgres instance"
  value = google_sql_database_instance.n8n_db_instance.connection_name
}
output "cloudsql_instance_ip_address" {
  description = "Private IP address of the Cloud SQL Postgres instance"
  value = google_sql_database_instance.n8n_db_instance.private_ip_address
}

# Cloud SQL database name
output "cloudsql_database_name" {
  description = "Database name in the Postgres instance for n8n"
  value = google_sql_database.n8n_database.name
}

output "cloudsql_user" {
  description = "Database user for the n8n database"
  value = google_sql_user.n8n_user.name
}

# Network configuration
output "vpc_network_name" {
  description = "Name of the VPC network"
  value = google_compute_network.vpc.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value = google_compute_network.vpc.id
}

output "subnet_name" {
 description = "Name of the subnet"
 value = google_compute_subnetwork.subnet.name 
}

output "subnet_id" {
  description = "ID of the subnet"
  value = google_compute_subnetwork.subnet.id
}

# Security and IAM
output "deploy_service_account_email" {
  description = "Service account email for Github Actions deployment"
  value = google_service_account.deploy_sa.email
}

# Monitoring and alerting
# output "uptime_check_id" {
#   description = "ID of the uptime check for crypto API"
#   value = google_monitoring_uptime_check_config.crypto_api.id
# }

# output "alert_policy_id" {
#   description = "ID of the alert policy for high error rates"
#   value = google_monitoring_alert_policy.crypto_api_high_error_rate.id
# }

# Environment information
output "environment" {
  description = "The environment being deployed to"
  value = var.environment
}

output "region" {
 description = "The GCP region where resources are deployed"
 value = var.REGION 
}

output "project_id" {
  description = "The GCP project ID"
  value = var.PROJECT_ID
}