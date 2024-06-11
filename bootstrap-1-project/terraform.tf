terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }

  encryption {
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.my_key
    }

    state {
      method = method.aes_gcm.state
      enforced = true
    }
  }
}
