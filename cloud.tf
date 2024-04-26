provider "google" {
  project = "pitlor-vps"
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
  zone_id = var.zone_id
  name    = "@"
  value   = google_compute_address.vps_ip_address.address
  type    = "A"
}

resource "cloudflare_record" "subdomain" {
  zone_id = var.zone_id
  name    = "*"
  value   = google_compute_address.vps_ip_address.address
  type    = "A"
}

resource "google_compute_instance" "vps" {
  name         = "vps"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = [var.vps_tag]
  hostname = "vps.pitlor.dev"

  metadata = {
    "ssh-keys" = "${var.vm_username}:${data.local_file.ssh_public_key}"
    "user-data" = data.cloudinit_config.install_puppet.rendered
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vps_network.name
    access_config {
      nat_ip = google_compute_address.vps_ip_address.address
    }
  }
}
