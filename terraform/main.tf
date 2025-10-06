# Enable Required APIs
resource "google_project_service" "enabled" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  project = var.PROJECT_ID
  service = each.key
}

# Networking - Custom VPC

resource "google_compute_network" "vpc" {
  name = "${var.App_name}-vpc"
  auto_create_subnetworks = false
  description = "Custom VPC for ${var.App_name}"
}

resource "google_compute_subnetwork" "subnet" {
  name = "${var.App_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region = var.REGION
  network = google_compute_network.vpc.id

  secondary_ip_range {
    range_name = "pods"
    ip_cidr_range = "10.1.0.0/16"
    }
  secondary_ip_range {
    range_name = "pods"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Firewall rule to allow internal communication within the VPC

resource "google_compute_firewall" "allow_internal" {
  name = "${var.App_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/24", "10.1.0.0/16", "10.2.0.0/16"]
}

# Artifact Registry

resource "google_artifact_registry_repository" "repo" {
  location = var.REGION
  repository_id = "${var.App_name}-repo"
  description = "Docker repo for ${var.App_name}"
  format = "DOCKER"

  docker_config {
    immutable_tags = false
  }
}
#####################
# Service Accounts
#####################

# Github Actions Deploy SA
resource "google_service_account" "deploy_sa" {
  account_id = "${var.App_name}-deploy"
  display_name = "CI/CD Deploy Service Account"
  description = "Service Account for GitHub Actions deployments"
}

# Runtime SA for Crypto API
resource "google_service_account" "crypto_api_sa" {
  account_id = "${var.App_name}-api-sa"
  display_name = "n8n Service Account"
  description = "Service Account for Crypto API Cloud Run service" 
}

# Runtime SA for n8n
resource "google_service_account" "n8n_sa" {
  account_id = "${var.App_name}-n8n-sa"
  display_name = "n8n Service Account"
  description = "Service Account for n8n Cloud Run service"
}

#####################
# IAM Bindings for Deploy SA - Minimal permissions for deployment
#####################
resource "google_project_iam_member" "deploy_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageViewer",
    "roles/compute.networkViewer",
    "roles/cloudsql.client"
  ])
  project = var.PROJECT_ID
  role = each.key
  member = "serviceAccount:${google_service_account.deploy_sa.email}"
}

#####################
# IAM for SA
#####################
# n8n SA permissions
resource "google_project_iam_member" "n8n_sql_client" {
  project = var.PROJECT_ID
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.n8n_sa.email}"
}


# resource "google_compute_network" "default" {
#   name = "default"
# }

# Crypto API SA permissions
resource "google_project_iam_member" "crypto_api_secret_accessor" {
  project = var.PROJECT_ID
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.crypto_api_sa.email}"
}
#####################
# Cloud SQL (Postgres for n8n)
#####################

# Private IP allocation
resource "google_compute_global_address" "private_ip_range" {
  name = "${var.App_name}-private-ip-range"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network = google_compute_network.vpc.self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "n8n_db_instance" {
  name = "${var.App_name}-n8n-db"
  region = var.REGION
  database_version = "POSTGRES_14"
  deletion_protection = "production" ? "db-g1-small":"db-f1-micro"

  settings {
    tier = var.environment == "production" ? "db-g1-small":"db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.vpc.id

      ssl_mode = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled = var.environment == "production" ? true : false
      start_time = "03:00"
      point_in_time_recovery_enabled = var.environment == "production" ? true : false
      transaction_log_retention_days = 7
    }

    maintenance_window {
      day = 7 # Sunday
      hour = 3 # 3 AM
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled = true
      query_plans_per_minute = 5
      query_string_length = 1024
      record_application_tags = true
      record_client_address = true
    }
  }

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
# Secrets Management (DB password + encryption key)
################
resource "google_secret_manager_secret" "n8n_db_password" {
  secret_id = "${var.App_name}-n8n-db-password"
  replication {
    auto {}
  }
  labels = {
    environment = var.environment
    service = "n8n"
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

# Crypto API database URL (if needed)

resource "google_secret_manager_secret" "crypto_api_db_url" {
  secret_id = "${var.App_name}-crypto-api-db-url"
  replication {
    auto {}
  }
  labels = {
    environment = var.environment
    service = "crypto-api"
  }
}

resource "google_secret_manager_secret_version" "crypto_api_db_url_v" {
  secret = google_secret_manager_secret.crypto_api_db_url.id
  secret_data = var.CRYPTO_API_DB_URL

}  

resource "google_secret_manager_secret_iam_member" "crypto_api_db_url_accessor" {
  secret_id = google_secret_manager_secret.crypto_api_db_url.id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.crypto_api_sa.email}"
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
      image = "${var.REGION}-docker.pkg.dev/${var.PROJECT_ID}/${google_artifact_registry_repository.repo.repository_id}/${var.App_name}-api:${var.image_tag}"
      ports {
        container_port = 8080
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.crypto_api_db_url.id
            version = "latest"
          }
        }
    }

    env {
      name = "ENVIRONMENT"
      value = var.environment 
    }

    env {
      name = "LOG_LEVEL"
      value = var.environment == "production" ? "INFO" : "DEBUG"
    }

    resources {
      limits = {
        memory = "512Mi"
        cpu    = "1000m"
      }
      cpu_idle = var.environment == "production" ? false : true
    }

    startup_probe {
      http_get {
        path = "/health"
        port = 8080
      }
      initial_delay_seconds = 10
      period_seconds = 10
      failure_threshold = 3
      timeout_seconds = 3
    }
    liveness_probe {
      http_get {
        path = "/health"
        port = 8080
      }
      initial_delay_seconds = 30
      period_seconds = 30
      failure_threshold = 3
      timeout_seconds = 3
      }
    }

    scaling {
      min_instance_count = var.environment == "production" ? 1 : 0
      max_instance_count = var.environment == "production" ? 100 : 10
    }
    timeout = "300s"
  }
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  lifecycle {
    ignore_changes = [template[0].containers[0].image]
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
      ports {
        container_port = 5678
      }
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
      env {
        name = "N8N_PORT"
        value = "5678"
      }
      env {
        name = "N8N_PROTOCOL"
        value = "https"
      }
      env {
        name = "n8n_BASIC_AUTH_ACTIVE"
        value = var.environment == "production" ? "true" : "false"
      }
      env {
        name = "N8N_BASIC_AUTH_USER"
        value = var.N8N_BASIC_AUTH_USER
      }

      env {
        name = "N8N_BASIC_AUTH_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.n8n_basic_auth_password.id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        cpu_idle = var.environment == "production" ? false : true
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

    scaling {
      min_instance_count = var.environment == "production" ? 1 : 0
      max_instance_count = var.environment == "production" ? 50 : 10
    }
    timeout = "300s"
  }
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "n8n_public" {
  name = google_cloud_run_v2_service.n8n.name
  location = var.REGION
  role = "roles/run.invoker"
  member = "allUsers"
}

##############
# Monitoring & alerting
##############

# resource "google_monitoring_uptime_check_config" "crypto_api" {
#   display_name = "${var.App_name}-api-uptime"
#   timeout = "10s"
#   period = "60s"

#   http_check {
#     path = "/health"
#     port = "443"
#     use_ssl = true
#     validate_ssl =  true
#     request_method = "GET"
#   }

#   monitored_resource {
#     type = "uptime_url"
#     labels = {
#       project_id = var.PROJECT_ID
#       host = google_cloud_run_v2_service.crypto_api.uri
#     }
#   }
#   content_matchers {
#     content = "healthy"
#   }
# }

# # Alert policy for Crypto API

# resource "google_monitoring_alert_policy" "crypto_api_high_error_rate" {
#  display_name = "${var.App_name}-api-high-error-rate"
#   combiner = "OR"

#   conditions {
#     display_name = "High Error Rate"
#     condition_threshold {
#       filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.crypto_api.name}\""
#       duration = "60s"
#       comparison = "COMPARISON_GT"
#       threshold_value = 0.1

#       aggregations {
#         alignment_period = "60s"
#         per_series_aligner = "ALIGN_RATE"
#       }

#       metric_name = "run.googleapis.com/request_count"
#     }
#   }
#   notification_channels = var.alert_notification_channels
# }