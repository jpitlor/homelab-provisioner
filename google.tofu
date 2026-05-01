provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}

###################
# VPS and network #
###################
resource "google_compute_network" "vps_network" {
  name = "vps-network"
}

resource "google_compute_firewall" "vps_firewall" {
  name    = "vps-firewall"
  network = google_compute_network.vps_network.self_link
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "22",    # SSH
      "80",    # HTTP
      "443",   # HTTPS
      "1194",  # OpenVPN
      # "25565", # Minecraft
    ]
  }

  target_tags = ["vps"]
}

resource "google_compute_address" "vps_ip_address" {
  name = "vps-ip-address"
}

resource "google_compute_instance" "vps" {
  name         = "vps"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = ["vps"]
  hostname = "vps.pitlor.dev"

  boot_disk {
    initialize_params {
      image = "vps-image-template"
    }
  }

  network_interface {
    network = google_compute_network.vps_network.name
    access_config {
      nat_ip = google_compute_address.vps_ip_address.address
    }
  }
}

######################################
# Service accounts and related roles #
######################################
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

resource "google_storage_bucket_iam_member" "container_backup_bucket_service_account" {
  bucket = google_storage_bucket.container_backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_storage_bucket_iam_member" "postgres_backup_bucket_service_account" {
  bucket = google_storage_bucket.postgres_backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero.name
}

output "velero_service_account_credentials" {
  value = base64decode(google_service_account_key.velero.private_key)
  sensitive = true
}


#############################
# Buckets and other storage #
#############################
resource "google_storage_bucket" "backup_bucket" {
  name = "dev-pitlor-homelab-nas-backups"
  location = var.gcp_region
  project = var.gcp_project
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
  location = var.gcp_region
  project = var.gcp_project

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
  location = var.gcp_region
  project = var.gcp_project

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "postgres_backup_bucket" {
  bucket = google_storage_bucket.postgres_backup_bucket.id
  role = "roles/storage.admin"
  member = "serviceAccount:${local.service_account.client_email}"
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

##############################
# Credentials to be exported #
##############################
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