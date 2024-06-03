provider "google" {
  credentials = file("./credentials.json")
  project = var.bootstrap_2_gcp_project_id
  region = var.bootstrap_2_gcp_region
}

locals {
  service_account = jsondecode(file("./credentials.json"))
}

resource "google_kms_key_ring" "storage_bucket" {
  name     = "storage-encryption-key-ring"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id
}

resource "google_kms_crypto_key" "storage_bucket" {
  name            = "storage-encryption-key"
  key_ring        = google_kms_key_ring.storage_bucket.id
  rotation_period = "86400s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "service_account" {
  crypto_key_id = google_kms_crypto_key.storage_bucket.id
  role          = "roles/cloudkms.cryptoKeyEncrypter"
  member        = "serviceAccount:${local.service_account.client_email}"
}

resource "google_storage_bucket" "terraform_state_bucket" {
  name = "terraform-state"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_bucket.id
  }
}
