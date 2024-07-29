provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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
      "25565", # Minecraft
      "1194"   # OpenVPN
    ]
  }

  target_tags = [var.vps_tag]
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

# TODO - getting errors for some reason
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
  tags         = [var.vps_tag]
  hostname = "vps.pitlor.dev"

  metadata = {
    "user-data" = data.cloudinit_config.ssh_ca.rendered
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/${var.gcp_ubuntu_version}"
    }
  }

  network_interface {
    network = google_compute_network.vps_network.name
    access_config {
      nat_ip = google_compute_address.vps_ip_address.address
    }
  }
}
