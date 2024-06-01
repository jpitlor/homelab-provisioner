variable "bootstrap_gcp_project" {
  description = "Project name for GCP"
  type = string
}

variable "bootstrap_gcp_region" {
  description = "Region for GCP project"
  type = string
  default = "us-central1"
}
