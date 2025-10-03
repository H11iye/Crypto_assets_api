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
  default = "LOKAloki_i11"
}

variable "N8N_ENCRYPTION_KEY" {
  type = string
  sensitive = true
  default = "1e063edf7dc14411dd5ef92c43a51c910aa6295d2810a21658101127943e996cvalue"
}

# Terraform variable for the image tag
variable "image_tag" {
  type        = string
  description = "The tag of the Docker image to deploy"
}