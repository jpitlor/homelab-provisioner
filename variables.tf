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

variable "gcp_ubuntu_version" {
  description = "Ubuntu version to use for VPS"
  type = string
  default = "ubuntu-2204-lts"
}

variable "vps_tag" {
  description = "Tag for the VM instance"
  type        = string
  default     = "vps"
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

variable "proxmox_username" {
  description = "Username for Proxmox"
  type = string
  default = "root"
}

variable "proxmox_user_domain" {
  description = "Domain for Proxmox user"
  type = string
  default = "pam"
}

variable "proxmox_password" {
  description = "Password for Proxmox"
  type = string
}

variable "proxmox_node_name" {
  description = "Name for Proxmox node"
  type = string
}

variable "proxmox_datastore" {
  description = "Datastore for system-level files"
  type = string
  default = "local"
}

variable "proxmox_disk_datastore" {
  description = "Datastore for VM disks"
  type = string
  default = "local-lvm"
}

# Created Resources
variable "haos_url" {
  description = "URL of the latest HAOS release"
  type = string
  default = "https://github.com/home-assistant/operating-system/releases/download/12.2/haos_generic-x86-64-12.2.img.xz"
}

variable "ubuntu_url" {
  description = "URL of the latest Ubuntu Server release"
  type = string
  default = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
}

variable "vm_username" {
  description = "Username for VM user account"
  type = string
}

data "cloudinit_config" "ssh_ca" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = file("cloud-config.yml")
    filename = "cloud-config.yml"
  }
}

