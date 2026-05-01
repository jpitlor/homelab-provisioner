variable "gcp_project" {
  description = "Project name for GCP"
  type = string
  default = "Homelab"
}

variable "gcp_region" {
  description = "Region for GCP project"
  type = string
  default = "us-central1"
}

variable "gcp_billing_account" {
  description = "Billing account number"
  type = string
}

variable "state_encryption_passphrase" {
  description = "State encryption passphrase"
  type = string
}
