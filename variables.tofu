#########################
# Google Cloud Platform #
#########################
variable "gcp_project" {
  description = "Project name for VPS on GCP"
  type = string
}

variable "gcp_region" {
  description = "Region for VPS on GCP"
  type = string
  default = "us-central1"
}

variable "gcp_buckets" {
  description = "List of buckets in GCP to create - the prefix dev-pitlor-homelab will be prepended"
  type = map(object({
    storage_class = string,
    enable_versioning = bool,
    credentials_type = string,
    service_account_id = string,
    service_account_name = string,
    service_account_permissions = list(string)
  }))
  default = {
    "velero_backups": {
      storage_class = "STANDARD",
      enable_versioning = false,
      service_account_name = "Velero",
      service_account_id = "velero",
      credentials_type = "json",
      service_account_permissions = [
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
    },
    "longhorn_backups": {
      storage_class = "STANDARD",
      enable_versioning = false,
      service_account_name = "Longhorn",
      service_account_id = "longhorn",
      credentials_type = "hmac",
      service_account_permissions = [
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
    },
    "postgres_backups": {
      storage_class = "STANDARD",
      enable_versioning = false,
      service_account_name = "Barman",
      service_account_id = "barman",
      credentials_type = "json",
      service_account_permissions = [
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
    },
    "synology_backups": {
      storage_class = "COLDLINE",
      enable_versioning = true,
      service_account_name = "Synology",
      service_account_id = "synology",
      credentials_type = "hmac",
      service_account_permissions = [
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
  }
}

##############
# Cloudflare #
##############
variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Zone ID of the domain"
  type        = string
}

###########
# Proxmox #
###########
variable "proxmox_endpoint" {
  description = "Endpoint for Proxmox"
  type = string
}

variable "pm_user" {
  description = "Username for Proxmox"
  type = string
}

variable "pm_realm" {
  description = "Domain for Proxmox user"
  type = string
  default = "pam"
}

variable "pm_password" {
  description = "Password for Proxmox"
  type = string
}

variable "proxmox_node_name" {
  description = "Name for Proxmox node"
  type = string
}

variable "proxmox_disk_datastore" {
  description = "Datastore for VM disks"
  type = string
  default = "local-lvm"
}

variable "proxmox_cluster_nodes" {
  description = "List of nodes in the Proxmox cluster"
  type = list(object({
    name = string,
    capacityGb = number,
    hasGpu = bool,
    cpuSockets = number,
    ramGb = number
  }))
}