variable "bootstrap_1_gcp_project" {
  description = "Project name for GCP"
  type = string
  default = "Homelab"
}

variable "bootstrap_1_gcp_region" {
  description = "Region for GCP project"
  type = string
  default = "us-central1"
}

variable "bootstrap_gcp_billing_account" {
  default = "Billing account number"
  type = string
}
