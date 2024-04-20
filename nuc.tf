provider "proxmox" {
  endpoint = "https://192.168.2.203:8006/"
  username = "root@pam"
  password = ""
  insecure = true
}

data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_server_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "nuc"
  url          = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "docker-containers"
  node_name = "nuc"

  initialization {
    user_account {
      username = "jpitlor"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
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
      username = "jpitlor"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
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
    host = "10c4:ea60"
  }
}
