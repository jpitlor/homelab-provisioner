provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = "${var.proxmox_username}@${var.proxmox_user_domain}"
  password = var.proxmox_password

  # TODO: This can be removed for prod, I assume?
  insecure = true
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.proxmox_snippet_datastore
  node_name    = var.proxmox_node_name

  source_raw {
    data = data.cloudinit_config.ssh_ca.rendered
    file_name = "cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_server_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore
  node_name    = var.proxmox_node_name
  url          = var.ubuntu_url
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  for_each = toset(["test-docker-containers", "test-vault", "test-dev-playground"])

  name      = each.key
  node_name = var.proxmox_node_name

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = var.proxmox_disk_datastore
    file_id      = proxmox_virtual_environment_download_file.ubuntu_server_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

resource "null_resource" "haos" {
  provisioner "local-exec" {
    command = "wget -O haos.img.xz ${var.haos_url} && unxz haos.img.xz"
  }
}

resource "proxmox_virtual_environment_file" "haos_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore
  node_name    = var.proxmox_node_name
  source_file {
    path = "haos.img"
  }
}

resource "proxmox_virtual_environment_vm" "haos_vm" {
  name      = "home-assistant"
  node_name = var.proxmox_node_name

  disk {
    datastore_id = var.proxmox_disk_datastore
    file_id      = proxmox_virtual_environment_file.haos_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  usb {
    # This is a Sonoff ZigBee dongle
    host = "10c4:ea60"
  }
}
