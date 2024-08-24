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
  description = "Billing account number"
  type = string
}

variable "bootstrap_1_state_encryption_passphrase" {
  description = "State encryption passphrase"
  type = string
}
