terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }

  encryption {
    key_provider "pbkdf2" "my_key" {
      passphrase = var.bootstrap_2_state_encryption_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.my_key
    }

    state {
      method = method.aes_gcm.state
      enforced = true
    }
  }
}
