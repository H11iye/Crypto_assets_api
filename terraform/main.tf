resource "google_project_service" "cloud_run" {
  project = var.PROJECT_ID
  service = "run.googleapis.com"
}

resource "google_project_service" "artifact_registry" {
  project = var.PROJECT_ID
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "secret_manager" {
  project = var.PROJECT_ID
  service = "secretmanager.googleapis.com"
}

# VPC + Subnet
resource "google_compute_network" "vpc" {
  name = "${var.App_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name = "${var.App_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region = var.REGION
  network = google_compute_network.vpc.id 
}

# Artifact Registry 

resource "google_artifact_registry_repository" "repo" {
  provider = google
  location = var.REGION
  repository_id = "${var.App_name}-repo"
  description = "Crypto assets repository for cloud run"
  format = "DOCKER"
}

# Service account for CI/CD deployments (created by Terraform)
resource "google_service_account" "Crypto_assets_MCP" {
    account_id = "${var.App_name}-deploy"
    display_name = "Crypto assets Service Account"
  
}

# IAM bindings for the CI deployer SA

resource "google_project_iam_member" "sa_run_admin" {
  project = var.PROJECT_ID
  role = "roles/run.admin"
  member = "serviceAccount:${google_service_account.Crypto_assets_MCP.email}"
}

resource "google_project_iam_member" "sa_artifact_writer" {
  project = var.PROJECT_ID
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.Crypto_assets_MCP.email}"
}

# Allow pushing image to Artifact Registry

resource "google_project_iam_member" "sa_storage_admin" {
  project = var.PROJECT_ID
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.Crypto_assets_MCP.email}"
}
# Allow accessing secrets 

resource "google_project_iam_member" "sa_secret_accessor" {
  project = var.PROJECT_ID
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.Crypto_assets_MCP.email}"
}

# Allow CI/CD pipeline SA to impersonate this SA

resource "google_project_iam_member" "sa_impersonate" {
  project = var.PROJECT_ID
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.Crypto_assets_MCP.email}"
}
# Make the Cloud Run service allow unauthenticated access
resource "google_cloud_run_service_iam_member" "public_invoker" {
  service = google_cloud_run_v2_service.service.name
  location = var.REGION
  role = "roles/run.invoker"
  member = "allUsers"
}

# Cloud Run placeholder service 

resource "google_cloud_run_v2_service" "service" {
  name = var.App_name
  location = var.REGION

  template {
    containers {
      
      image = "gcr.io/cloudrun/hello" # place holder
    }
  }
}