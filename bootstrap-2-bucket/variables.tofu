variable "bootstrap_2_gcp_project_id" {
  description = "Project name for GCP"
  type = string
  default = "dev-pitlor-test-homelab"
}

variable "bootstrap_2_gcp_region" {
  description = "Region for GCP project"
  type = string
  default = "us-central1"
}

variable "bootstrap_2_state_encryption_passphrase" {
  description = "State encryption passphrase"
  type = string
}
