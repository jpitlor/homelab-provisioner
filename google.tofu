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
      "22",    # SSH Proxy
      "2222",  # SSH
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
      type = "pd-standard"
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
resource "google_service_account" "homelab" {
  for_each = var.gcp_buckets

  project = var.gcp_project
  account_id = each.value.service_account_id
  display_name = each.value.service_account_name
}

resource "google_project_iam_custom_role" "homelab" {
  for_each = var.gcp_buckets

  project = var.gcp_project
  title = "${each.value.service_account_name} Service Account"
  role_id = "${each.value.service_account_id}ServiceAccount"
  permissions = each.value.service_account_permissions
}

resource "google_project_iam_member" "homelab" {
  for_each = var.gcp_buckets

  project = var.gcp_project
  role    = google_project_iam_custom_role.homelab[each.key].id
  member = "serviceAccount:${google_service_account.homelab[each.key].email}"
}

resource "google_service_account" "homelab_chart" {
  project = var.gcp_project
  account_id = "homelab-chart"
  display_name = "Homelab Chart"
}


#############################
# Buckets and other storage #
#############################
resource "google_storage_bucket" "homelab" {
  for_each = var.gcp_buckets

  name = "dev-pitlor-homelab-${each.key}"
  location = var.gcp_region
  project = var.gcp_project
  storage_class = each.value.storage_class

  versioning {
    enabled = each.value.enable_versioning
  }

}

resource "google_storage_bucket_iam_member" "homelab" {
  for_each = var.gcp_buckets

  bucket = google_storage_bucket.homelab[each.key].id
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.homelab[each.key].email}"
}

resource "google_artifact_registry_repository" "chart_repository" {
  location      = "us-central1"
  repository_id = "homelab-chart"
  description   = "Helm Chart repository"
  format        = "DOCKER"
}

resource "time_sleep" "wait_repository_create" {
  depends_on = [google_artifact_registry_repository.chart_repository]
  create_duration = "10s"
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  project = google_artifact_registry_repository.chart_repository.project
  location = google_artifact_registry_repository.chart_repository.location
  repository = google_artifact_registry_repository.chart_repository.name
  role = "roles/artifactregistry.admin"
  members = [
    "user:jpitlor@gmail.com",
    "serviceAccount:${google_service_account.homelab_chart.email}",
  ]

  depends_on = [time_sleep.wait_repository_create]
}

resource "google_artifact_registry_repository_iam_binding" "binding_public" {
  project = google_artifact_registry_repository.chart_repository.project
  location = google_artifact_registry_repository.chart_repository.location
  repository = google_artifact_registry_repository.chart_repository.name
  role = "roles/artifactregistry.reader"
  members = ["allUsers"]

  depends_on = [time_sleep.wait_repository_create]
}

##############################
# Credentials to be exported #
##############################
resource "google_storage_hmac_key" "homelab" {
  for_each = { for name, bucket in var.gcp_buckets : name => bucket if bucket.credentials_type == "hmac" }
  service_account_email = google_service_account.homelab[each.key].email
}

resource "google_service_account_key" "homelab" {
  for_each = { for name, bucket in var.gcp_buckets : name => bucket if bucket.credentials_type == "json" }
  service_account_id = google_service_account.homelab[each.key].name
}

output "service_account_json_credentials" {
  value = {
    for bucket, credentials in google_service_account_key.homelab : bucket => base64decode(credentials.private_key)
  }

  sensitive = true
}

output "service_account_hmac_credentials" {
  value = {
    for bucket, key in google_storage_hmac_key.homelab : bucket => {
      "key": key.access_id,
      "secret": key.secret
    }
  }

  sensitive = true
}