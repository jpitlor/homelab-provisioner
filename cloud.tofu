provider "google" {
  project = var.gcp_project
  region = var.gcp_region
  credentials = file("./credentials.json")
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  service_account = jsondecode(file("./credentials.json"))
}

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

resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "test" # @
  value   = google_compute_address.vps_ip_address.address
  type    = "A"
}

resource "cloudflare_record" "subdomain" {
  zone_id = var.cloudflare_zone_id
  name    = "*.test" # *
  value   = google_compute_address.vps_ip_address.address
  type    = "A"
}

# resource "cloudflare_record" "minecraft" {
#   zone_id = var.cloudflare_zone_id
#   name    = "_minecraft._tcp"
#   type    = "SRV"
#
#   data {
#     service  = "_minecraft"
#     proto    = "_tls"
#     name     = "minecraft-srv"
#     priority = 0
#     weight   = 0
#     port     = 25565
#     target   = "minecraft.pitlor.dev"
#   }
# }

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
