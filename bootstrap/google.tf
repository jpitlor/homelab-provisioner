provider "google" { }

resource "google_project" "homelab" {
  name       = var.bootstrap_gcp_project
  project_id = var.bootstrap_gcp_project
}

resource "google_project_service" "kms_api" {
  project = google_project.homelab.name
  service = "cloudkms.googleapis.com"
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_project_service.kms_api]
  create_duration = "30s"
}

resource "google_kms_key_ring" "storage_bucket" {
  name     = "storage-encryption-key-ring"
  location = var.bootstrap_gcp_region
  depends_on = [time_sleep.wait_30_seconds]
}

resource "google_kms_crypto_key" "storage_bucket" {
  name            = "storage-encryption-key"
  key_ring        = google_kms_key_ring.storage_bucket.name
  rotation_period = "86400s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "terraform_state_bucket" {
  name = "terraform-state"
  location = var.bootstrap_gcp_region

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_bucket.name
  }
}
