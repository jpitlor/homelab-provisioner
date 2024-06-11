provider "google" { }

resource "google_project" "homelab" {
  name       = var.bootstrap_1_gcp_project
  project_id = "dev-pitlor-test-${lower(var.bootstrap_1_gcp_project)}"
  billing_account = var.bootstrap_gcp_billing_account
}

resource "time_sleep" "wait_project_create" {
  depends_on = [google_project.homelab]
  create_duration = "30s"
}

resource "google_project_service" "apis" {
  for_each = toset(["cloudkms", "iam", "compute"])

  depends_on = [time_sleep.wait_project_create]
  project = google_project.homelab.project_id
  service = "${each.key}.googleapis.com"
}

resource "google_service_account" "homelab" {
  project = google_project.homelab.project_id
  account_id = "terraform"
  display_name = "Terraform"
}

resource "google_project_iam_custom_role" "terraform" {
  project = google_project.homelab.project_id
  title = "Terraform Service Account"
  role_id = "terraformServiceAccount"
  permissions = [
    "cloudkms.keyRings.get",
    "cloudkms.keyRings.create",
    "cloudkms.cryptoKeys.get",
    "cloudkms.cryptoKeys.getIamPolicy",
    "cloudkms.cryptoKeys.setIamPolicy",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.delete"
  ]
}

resource "google_project_iam_member" "crypto_key" {
  project = google_project.homelab.project_id
  role    = google_project_iam_custom_role.terraform.id
  member = "serviceAccount:${google_service_account.homelab.email}"
}

resource "google_service_account_key" "homelab" {
  service_account_id = google_service_account.homelab.name
}

resource "local_file" "service_account_json" {
  content = base64decode(google_service_account_key.homelab.private_key)
  filename = "../bootstrap-2-bucket/credentials.json"
}

