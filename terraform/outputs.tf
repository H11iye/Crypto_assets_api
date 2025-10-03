# Artifact registry outputs
output "artifact_registry_repo" {
  description = "Artifact registry repository ID for container images"
  value = google_artifact_registry_repository.repo.repository_id
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
  description = "Public IP address of the Cloud SQL Postgres instance"
  value = google_sql_database_instance.n8n_db_instance.public_ip_address
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