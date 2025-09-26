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