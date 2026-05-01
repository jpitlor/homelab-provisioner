variable "bootstrap_2_gcp_project_id" {
  description = "Project name for GCP"
  type = string
  default = "dev-pitlor-homelab"
}

variable "bootstrap_2_gcp_region" {
  description = "Region for GCP project"
  type = string
  default = "us-central1"
}

variable "bootstrap_2_state_encryption_passphrase" {
  description = "State encryption passphrase"
  type = string
}

variable "buckets" {
  description = "List of buckets in GCP to create - the prefix dev-pitlor-homelab will be prepended"
  type = list(object({
    name = string,
    service_account_name = string
  }))
  default = [
    {
      name = "velero-backups", 
      service_account_name = "velero"
    },
    {
      name = "longhorn-backups", 
      service_account_name = "longhorn"
    },
    {
      name = "postgres-backups", 
      service_account_name = "barman"
    },
    {
      name = "nas-backups",
      service_account_name = "nas"
    },
    {
      name = "opentofu-state",
      service_account_name = "terraform"
    }
  ]
}

variable "bucket_service_accounts" {
  description = "List of service accounts in GCP to create"
  type = list(object({
    name = string,
    permissions = list(string)
  }))
  default = [
    {
      name = "velero",
      permissions = [ "value" ]
    },
    {
      name = "longhorn",
      permissions = [ "value" ]
    },
    {
      name = "barman",
      permissions = [ "value" ]
    },
    {
      name = "nas",
      permissions = [ "value" ]
    }
  ]
}