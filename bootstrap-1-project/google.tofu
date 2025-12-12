provider "google" { }

resource "google_project" "homelab" {
  name       = var.bootstrap_1_gcp_project
  project_id = "dev-pitlor-${lower(var.bootstrap_1_gcp_project)}"
  billing_account = var.bootstrap_gcp_billing_account
}

resource "time_sleep" "wait_project_create" {
  depends_on = [google_project.homelab]
  create_duration = "30s"
}

resource "google_project_service" "apis" {
  for_each = toset([
    "calendar-json",
    "maps-embed-backend",
    "cloudkms",
    "iam",
    "compute",
    "cloudresourcemanager",
    "artifactregistry"
  ])

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
    "cloudkms.cryptoKeys.update",
    "cloudkms.cryptoKeys.create",
    "cloudkms.cryptoKeys.getIamPolicy",
    "cloudkms.cryptoKeys.setIamPolicy",
    "storage.buckets.create",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.buckets.delete",
    "storage.buckets.getIamPolicy",
    "storage.buckets.setIamPolicy",
    "storage.objects.list",
    "storage.objects.delete",
    "storage.hmacKeys.create",
    "storage.hmacKeys.list",
    "storage.hmacKeys.get",
    "storage.hmacKeys.delete",
    "storage.hmacKeys.update",
    "compute.disks.create",
    "compute.disks.delete",
    "compute.firewalls.get",
    "compute.firewalls.delete",
    "compute.firewalls.create",
    "compute.firewalls.update",
    "compute.instances.get",
    "compute.instances.delete",
    "compute.instances.create",
    "compute.instances.setTags",
    "compute.instances.setMetadata",
    "compute.networks.get",
    "compute.networks.updatePolicy",
    "compute.networks.delete",
    "compute.networks.create",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.addresses.get",
    "compute.addresses.use",
    "compute.addresses.create",
    "compute.addresses.delete",
    "compute.zones.get",
    "compute.images.get",
    "compute.images.useReadOnly",
    "compute.images.getFromFamily",
    "resourcemanager.projects.get",
    "artifactregistry.repositories.create",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.delete",
    "artifactregistry.repositories.getIamPolicy",
    "artifactregistry.repositories.setIamPolicy",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.update",
    "iam.serviceAccountKeys.create",
    "iam.serviceAccountKeys.list",
    "iam.serviceAccountKeys.get",
    "iam.serviceAccountKeys.delete",
    "iam.serviceAccountKeys.update"
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
  for_each = toset(["../bootstrap-2-bucket", ".."])

  content = base64decode(google_service_account_key.homelab.private_key)
  filename = "${each.key}/credentials.json"
}
