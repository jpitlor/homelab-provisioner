terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.53.1"
    }

    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.25.0"
    }
  }
}
