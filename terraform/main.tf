# Enable Required APIs
resource "google_project_service" "enabled" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com"
  ])
  project = var.PROJECT_ID
  service = each.key
}

# Networking

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
  location = var.REGION
  repository_id = "${var.App_name}-repo"
  description = "Docker repo for crypto API"
  format = "DOCKER"
}
#####################
# Service Accounts
#####################

# Github Actions Deploy SA
resource "google_service_account" "deploy_sa" {
  account_id = "${var.App_name}-deploy"
  display_name = "CI/CD Deploy Service Account"
}

# Runtime SA for Crypto API
resource "google_service_account" "crypto_api_sa" {
  account_id = "${var.App_name}-api-sa"
  display_name = "n8n Service Account"
}

# Runtime SA for n8n
resource "google_service_account" "n8n_sa" {
  account_id = "${var.App_name}-n8n-sa"
  display_name = "n8n Service Account"
}

#####################
# IAM Bindings for Deploy SA
#####################
resource "google_project_iam_member" "deploy_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/compute.networkAdmin",
    "roles/cloudsql.admin"
  ])
  project = var.PROJECT_ID
  role = each.key
  member = "serviceAccount:${google_service_account.deploy_sa.email}"
}

#####################
# IAM for n8n SA (Cloud SQL access)
#####################

resource "google_project_iam_member" "n8n_sql_client" {
  project = var.PROJECT_ID
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.n8n_sa.email}"
}

#####################
# Cloud SQL (Postgres for n8n)
#####################

resource "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "private_ip_range" {
  name = "private-ip-range"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.default.id
}
resource "google_service_networking_connection" "private_vpc_connection" {
  network = google_compute_network.default.self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "n8n_db_instance" {
  name = "${var.App_name}-n8n-db"
  region = var.REGION
  database_version = "POSTGRES_14"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.default.id
      ssl_mode = "ENCRYPTED_ONLY"

    }
  }
  deletion_protection = false
  depends_on = [ google_service_networking_connection.private_vpc_connection ]

}

resource "google_sql_database" "n8n_database" {
  name = "n8n"
  instance = google_sql_database_instance.n8n_db_instance.name
}

resource "google_sql_user" "n8n_user" {
  name = "n8n_user"
  instance = google_sql_database_instance.n8n_db_instance.name
  password = var.N8N_DB_PASSWORD
}


################
# Secrets (DB password + encryption key)
################
resource "google_secret_manager_secret" "n8n_db_password" {
  secret_id = "${var.App_name}-n8n-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "n8n_db_password_v" {
  secret = google_secret_manager_secret.n8n_db_password.id
  secret_data = var.N8N_DB_PASSWORD
}

resource "google_secret_manager_secret_iam_member" "n8n_secret_accessor" {
  secret_id = google_secret_manager_secret.n8n_db_password.id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.n8n_sa.email}"
}

################
# Cloud Run - Crypto API
################
resource "google_cloud_run_v2_service" "crypto_api" {
  name = "${var.App_name}-api"
  location = var.REGION

  template {
    service_account = google_service_account.crypto_api_sa.email
    containers {
      # Image will be pushed by GitHub Actions
      image = "${var.REGION}-docker.pkg.dev/${var.PROJECT_ID}/${var.App_name}-repo/${var.App_name}-api:${var.image_tag}"

    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "crypto_api_public" {
  name     = google_cloud_run_v2_service.crypto_api.name
  location = var.REGION
  role     = "roles/run.invoker"
  member   = "allUsers"
}

################
# Cloud Run - n8n
################
resource "google_cloud_run_v2_service" "n8n" {
  name = "${var.App_name}-n8n"
  location = var.REGION
  template {
    service_account = google_service_account.n8n_sa.email

    containers {
      image = "docker.n8n.io/n8nio/n8n:latest"

      env {
        name = "DB_TYPE"
        value = "postgres"
      }
      env {
        name = "DB_POSTGRESDB_DATABASE"
        value = google_sql_database.n8n_database.name
      }
      env {
        name = "DB_POSTGRESDB_USER"
        value = google_sql_user.n8n_user.name
      }

      env {
        name = "DB_POSTGRESDB_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.n8n_db_password.id
            version = "latest"
          }
        }
      }

      env {
        name = "DB_POSTGRESDB_HOST"
        value = "/cloudsql/${google_sql_database_instance.n8n_db_instance.connection_name}"
      }

      env {
        name = "N8N_ENCRYPTION_KEY"
        value = var.N8N_ENCRYPTION_KEY
      }
      
      volume_mounts {
        name = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.n8n_db_instance.connection_name]
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "n8n_public" {
  name = google_cloud_run_v2_service.n8n.name
  location = var.REGION
  role = "roles/run.invoker"
  member = "allUsers"
}