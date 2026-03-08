terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }

    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.34.0"
    }
  }

  backend "gcs" {
    bucket = "dev-pitlor-homelab-opentofu-state"
  }
}
