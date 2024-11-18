terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
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
