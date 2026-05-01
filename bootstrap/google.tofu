##############################
# STEP 1: Create the project #
##############################
provider "google" { }

resource "google_project" "homelab" {
  name       = var.gcp_project
  project_id = "dev-pitlor-${lower(var.gcp_project)}"
  billing_account = var.gcp_billing_account
}

resource "time_sleep" "wait_project_create" {
  depends_on = [google_project.homelab]
  create_duration = "30s"
}

################################
# STEP 2: Enable relevant APIs #
################################
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

##################################################################################
# STEP 3: Create a service account and attached role/IAM bindings to impersonate #
#         for future Terraform operations                                        #
##################################################################################
resource "google_service_account" "terraform" {
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
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
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
    "iam.serviceAccountKeys.update",
    "iam.roles.create",
    "iam.roles.list",
    "iam.roles.get",
    "iam.roles.delete",
    "iam.roles.update"
  ]
}

resource "google_project_iam_member" "terraform_account_terraform_role" {
  project = google_project.homelab.project_id
  role    = google_project_iam_custom_role.terraform.id
  member = "serviceAccount:${google_service_account.terraform.email}"
}

###############################################################
# STEP 4: Create an encrypted bucket to use for state storage #
###############################################################
resource "google_kms_key_ring" "storage_bucket" {
  name     = "storage-encryption-key-ring"
  location = var.gcp_region
  project = google_project.homelab.project_id
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
    "service-${google_project.homelab.number}@gs-project-accounts.iam.gserviceaccount.com",
    google_service_account.terraform.email
  ])

  crypto_key_id = google_kms_crypto_key.storage_bucket.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.key}"
}

resource "google_storage_bucket" "opentofu_state_bucket" {
  name = "dev-pitlor-homelab-opentofu-state"
  location = var.gcp_region
  project = google_project.homelab.project_id

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
  member = "serviceAccount:${google_service_account.terraform.email}"
}