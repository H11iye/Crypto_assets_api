variable "PROJECT_ID" {
  type = string
  description = "the GCP project ID"
}

variable "REGION" {
    type = string
    default = "us-central1"
  
}

variable "App_name" {
  type = string
  default = "crypto-assets-with-mcp"
}

variable "N8N_DB_PASSWORD" {
  type = string
  sensitive = true
}

variable "N8N_ENCRYPTION_KEY" {
  type = string
  sensitive = true
}