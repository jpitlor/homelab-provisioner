variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "zone_id" {
  description = "The Zone ID of the domain"
  type        = string
}

provider "google" {
  project = "pitlor-vps"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "google_compute_network" "vpc_network" {
  name = "homelab-network"
}

resource "google_compute_address" "vpc_ip_address" {
  name = "vpc-ip-address"
}

# Firewall Rules

resource "cloudflare_record" "root" {
  zone_id = var.zone_id
  name    = "@"
  value   = google_compute_address.vpc_ip_address.address
  type    = "A"
}

resource "cloudflare_record" "subdomain" {
  zone_id = var.zone_id
  name    = "*"
  value   = google_compute_address.vpc_ip_address.address
  type    = "A"
}

resource "google_compute_instance" "vps" {
  name         = "vps"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  # set SSH keys and password
  # create image
  # add puppet agent

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.vpc_ip_address.address
    }
  }
}
