variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "vm_username" {
  description = "Username for VM user account"
  type = string
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

data "cloudinit_config" "install_ansible" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = file("cloud-config.yml")
    filename = "cloud-config.yml"
  }
}

data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}
