provider "google" {
  credentials = file("./credentials.json")
  project = var.bootstrap_2_gcp_project_id
  region = var.bootstrap_2_gcp_region
}

locals {
  service_account = jsondecode(file("./credentials.json"))
}

data "google_project" "project" {
}

resource "google_kms_key_ring" "storage_bucket" {
  name     = "storage-encryption-key-ring"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id
}

resource "google_kms_crypto_key" "storage_bucket" {
  name            = "storage-encryption-key"
  key_ring        = google_kms_key_ring.storage_bucket.id

  # Only rotate every 15 days - more keys = more cost, so having only two keys active at any time (they get destroyed every 30 days) will help keep costs down
  # TODO: Add a Lambda function that automatically re-encrypts the state so it doesn't become inaccessible
  rotation_period = "1296000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "service_account" {
  for_each = toset([
    "service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com",
    local.service_account.client_email
  ])

  crypto_key_id = google_kms_crypto_key.storage_bucket.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.key}"
}

resource "google_storage_bucket" "opentofu_state_bucket" {
  name = "dev-pitlor-homelab-opentofu-state"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_bucket.id
  }
}

resource "google_storage_bucket_iam_member" "opentofu_state_bucket" {
  bucket = google_storage_bucket.opentofu_state_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${local.service_account.client_email}"
}

resource "google_storage_bucket" "backup_bucket" {
  name = "dev-pitlor-homelab-nas-backups"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id
  storage_class = "COLDLINE"

  versioning {
    enabled = false
  }
}

resource "google_storage_bucket_iam_member" "backup_bucket" {
  bucket = google_storage_bucket.backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${local.service_account.client_email}"
}

resource "google_storage_bucket" "container_backup_bucket" {
  name = "dev-pitlor-homelab-container-backups"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "container_backup_bucket" {
  bucket = google_storage_bucket.container_backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${local.service_account.client_email}"
}

resource "google_storage_bucket" "postgres_backup_bucket" {
  name = "dev-pitlor-homelab-postgres-backups"
  location = var.bootstrap_2_gcp_region
  project = var.bootstrap_2_gcp_project_id

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "postgres_backup_bucket" {
  bucket = google_storage_bucket.postgres_backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${local.service_account.client_email}"
}

resource "google_storage_hmac_key" "storage" {
  service_account_email = local.service_account.client_email
}

output "access_key" {
  value = google_storage_hmac_key.storage.access_id
}

output "secret_key" {
  value     = google_storage_hmac_key.storage.secret
  sensitive = true
}

resource "google_artifact_registry_repository" "chart-repository" {
  location      = "us-central1"
  repository_id = "homelab-chart"
  description   = "Helm Chart repository"
  format        = "DOCKER"
}

resource "time_sleep" "wait_repository_create" {
  depends_on = [google_artifact_registry_repository.chart-repository]
  create_duration = "10s"
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  project = google_artifact_registry_repository.chart-repository.project
  location = google_artifact_registry_repository.chart-repository.location
  repository = google_artifact_registry_repository.chart-repository.name
  role = "roles/artifactregistry.admin"
  members = [
    "user:jpitlor@gmail.com",
    "serviceAccount:${local.service_account.client_email}",
  ]

  depends_on = [time_sleep.wait_repository_create]
}

resource "google_artifact_registry_repository_iam_binding" "binding_public" {
  project = google_artifact_registry_repository.chart-repository.project
  location = google_artifact_registry_repository.chart-repository.location
  repository = google_artifact_registry_repository.chart-repository.name
  role = "roles/artifactregistry.reader"
  members = ["allUsers"]

  depends_on = [time_sleep.wait_repository_create]
}


resource "google_service_account" "velero" {
  project = data.google_project.project.project_id
  account_id = "velero"
  display_name = "Velero"
}

resource "google_project_iam_custom_role" "velero" {
  project = data.google_project.project.project_id
  title = "Velero Service Account"
  role_id = "veleroServiceAccount"
  permissions = [
    "compute.disks.get",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.projects.get",
    "compute.snapshots.get",
    "compute.snapshots.create",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
    "compute.snapshots.setLabels",
    "compute.zones.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "iam.serviceAccounts.signBlob"
  ]
}

resource "google_project_iam_member" "crypto_key" {
  project = data.google_project.project.project_id
  role    = google_project_iam_custom_role.velero.id
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero.name
}

output "velero_service_account_credentials" {
  value = base64decode(google_service_account_key.velero.private_key)
  sensitive = true
}