provider "proxmox" {
  endpoint = "https://${var.proxmox_endpoint}:8006"
  username = "${var.proxmox_username}@${var.proxmox_user_domain}"
  password = var.proxmox_password

  # TODO: This can be removed for prod, I assume?
  insecure = true

  ssh {
    agent = true

    node {
      name    = var.proxmox_node_name
      address = var.proxmox_endpoint
    }
  }
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
  tags = [each.key]
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
    size         = 64
  }

  network_device {
    bridge = "vmbr0"
  }

  cpu {
    cores = each.key == "test-docker-containers" ? 6 : 2
  }

  memory {
    dedicated = each.key == "test-docker-containers" ? 12288 : 2048
  }
}

resource "null_resource" "haos" {
  provisioner "local-exec" {
    command = "if [ ! -f haos.img ]; then wget -O haos.img.xz ${var.haos_url} && unxz haos.img.xz; fi"
  }
}

resource "proxmox_virtual_environment_file" "haos_image" {
  depends_on = [null_resource.haos]

  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore
  node_name    = var.proxmox_node_name
  source_file {
    path = "haos.img"
  }
}

resource "proxmox_virtual_environment_vm" "haos_vm" {
  name = "home-assistant-test"
  tags = ["home-assistant"]
  node_name = var.proxmox_node_name

  disk {
    datastore_id = var.proxmox_disk_datastore
    file_id      = proxmox_virtual_environment_file.haos_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 64
  }

  usb {
    # This is a Sonoff ZigBee dongle
    host = "10c4:ea60"
  }

  network_device {
    bridge = "vmbr0"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 3072
  }
}
