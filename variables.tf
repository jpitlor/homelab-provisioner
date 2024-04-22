variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "vm_username" {
  description = "Username for VM user account"
  type = string
  default = "jpitlor"
}

variable "vm_password" {
  description = "Password for VM user account"
  type = string
}

variable "zone_id" {
  description = "The Zone ID of the domain"
  type        = string
}

variable "vps_tag" {
  description = "Tag for the VM instance"
  type        = string
  default     = "vps"
}

data "local_file" "startup_script" {
  filename = "./install_puppet.sh"
}

data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}
