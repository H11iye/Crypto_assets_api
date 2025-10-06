variable "PROJECT_ID" {
  type = string
  description = "the GCP project ID"
  validation {
    condition     = length(var.PROJECT_ID) > 0
    error_message = "The PROJECT_ID variable must not be empty."
  }
}

variable "REGION" {
    type = string
    default = "us-central1"
  validation {
    condition     = contains([
      "us-central1",
      "us-east1",
      "us-east4",
      "us-west1",
      "us-west2",
      "europe-west1",
      "europe-west2",
      "europe-west3",
      "asia-east1",
      "asia-northeast1",
      "asia-south1"
    ], var.REGION
    )
    error_message = "The REGION must be a valid GCP region."
  }
}

variable "App_name" {
  type = string
  default = "crypto-assets-with-mcp"
  description = "the name of the application"
  validation {
    condition     = length(var.App_name) > 0 && length(var.App_name) <= 32
    error_message = "App name must be between 1 and 32 characters long."
  }
}

variable "environment" {
  type = string
  default = "development"
  description = "the environment (development, staging, production)"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}
variable "N8N_DB_PASSWORD" {
  type = string
  sensitive = true
  description = "Password for the n8n PostgreSQL database"

  validation {
    condition     = length(var.N8N_DB_PASSWORD) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "N8N_ENCRYPTION_KEY" {
  type = string
  sensitive = true
  description = "Encryption key for n8n"

  validation {
    condition     = length(var.N8N_ENCRYPTION_KEY) == 32
    error_message = "Encryption key must be exactly 32 characters long."
  }
}

variable "N8N_BASIC_AUTH_USER" {
  type = string
  default = "admin"
  description = "Basic auth username for n8n"
}
variable "N8N_BASIC_AUTH_PASSWORD" {
 type = string
 sensitive = true
  description = "Basic auth password for n8n"
  validation {
    condition     = length(var.N8N_BASIC_AUTH_PASSWORD) > 12
    error_message = "Basic auth password must be at least 12 characters long."
  }
}

variable "CRYPTO_API_DB_URL" {
  type = string
  sensitive = true
  description = "Database URL for the Crypto API"
}

# Terraform variable for the image tag
variable "image_tag" {
  type        = string
  description = "The tag of the Docker image to deploy"
   default = "latest"

  validation {
    condition = length(var.image_tag) > 0
    error_message = "Image tag cannot be empty."
  }
}

variable "alert_notification_channels" {
  type = list(string)
  default = []
  description = "List of alert notification channel IDs"
}

variable "crypto_api_cpu_limit" {
  type = string
  default = "1000m"
  description = "CPU limit for the Crypto API containers"
}

variable "crypto_api_memory_limit" {
  type = string
  default = "512Mi"
  description = "Memory limit for the Crypto API containers"
}

variable "n8n_cpu_limit" {
  type = string
  default = "2000m"
  description = "CPU limit for the n8n containers"
}

variable "n8n_memory_limit" {
  type = string
  default = "2Gi"
  description = "Memory limit for the n8n containers"
}

variable "crypto_api_min_instances" {
  type = number
  default = 0
  description = "Minimum number of instances for the Crypto API"
}

variable "crypto_api_max_instances" {
  type = number
  default = 10
  description = "Maximum number of instances for the Crypto API"
}

variable "n8n_min_instances" {
  type = number
  default = 0
  description = "Minimum number of instances for n8n"
}

variable "n8n_max_instances" {
  type = number
  default = 5
  description = "Maximum number of instances for n8n"
}

variable "enable_backup" {
  type = bool
  default = false
  description = "Enable automated backups for Cloud SQL"
}

variable "backup_start_time" {
  type = string
  default = "03:00"
  description = "Start time for daily backups (HH:MM format)"
}