output "artifact_registry_repo" {
  value = google_artifact_registry_repository.repo.repository_id
}

output "cloud_run_url" {
  value = google_cloud_run_v2_service.service.uri
}

output "service_account_email" {
    value = google_service_account.Crypto_assets_MCP.email
}