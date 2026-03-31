# Google Cloud Platform
variable "gcp_project" {
  description = "Project name for VPS on GCP"
  type = string
}

variable "gcp_region" {
  description = "Region for VPS on GCP"
  type = string
  default = "us-central1"
}

# Cloudflare
variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Zone ID of the domain"
  type        = string
}

# Proxmox
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