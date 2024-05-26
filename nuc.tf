provider "proxmox" {
  endpoint = "https://192.168.2.203:8006/"
  username = "root@pam"
  password = var.vm_password
  insecure = true
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "nuc"

  source_raw {
    data = data.cloudinit_config.install_ansible.rendered
    file_name = "cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_server_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "nuc"
  url          = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
}

resource "proxmox_virtual_environment_vm" "docker_containers_vm" {
  name      = "docker-containers"
  node_name = "nuc"

  initialization {
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_server_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

resource "proxmox_virtual_environment_vm" "vault_vm" {
  name      = "vault"
  node_name = "nuc"

  initialization {
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_server_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

resource "proxmox_virtual_environment_vm" "dev_playground_vm" {
  name      = "dev_playground"
  node_name = "nuc"

  initialization {
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_server_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

resource "proxmox_virtual_environment_download_file" "haos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "nuc"
  url          = "https://github.com/home-assistant/operating-system/releases/download/12.2/haos_generic-x86-64-12.2.img.xz"
}

resource "proxmox_virtual_environment_vm" "haos_vm" {
  name      = "home-assistant"
  node_name = "nuc"

  initialization {
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.haos_image.id
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
