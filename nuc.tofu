provider "proxmox" {
  pm_api_url = "https://${var.proxmox_endpoint}:8006/api2/json"
  pm_user = "${var.pm_user}@${var.pm_realm}"
  pm_password = var.pm_password

  # TODO: This can be removed for prod, I assume?
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "docker_containers_vm" {
  name = "docker-containers-test"
  clone = "docker-containers-template"
  tags = "docker_containers"
  target_node = var.proxmox_node_name

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.proxmox_disk_datastore
          size = 64
        }
      }
    }
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  sockets = 4
  memory = 12288
}

resource "proxmox_vm_qemu" "dev_playground_vm" {
  name = "dev-playground"
  tags = "dev_playground"
  clone = "dev-playground-template"
  target_node = var.proxmox_node_name

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.proxmox_disk_datastore
          size = 64
        }
      }
    }
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  sockets = 2
  memory = 2048
}

resource "proxmox_vm_qemu" "vault_vm" {
  name = "vault"
  tags = "vault"
  clone = "vault-template"
  target_node = var.proxmox_node_name
  vm_state = "stopped"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.proxmox_disk_datastore
          size = 64
        }
      }
    }
  }

  sockets = 2
  memory = 2048
}

# resource "proxmox_vm_qemu" "home_assistant_vm" {
#   name = "home-assistant"
#   tags = "home_assistant"
#   clone = "home-assistant-template"
#   target_node = var.proxmox_node_name
#
#   disks {
#    scsi {
#      scsi0 {
#        disk {
#          storage = var.proxmox_disk_datastore
#          size = 64
#        }
#      }
#    }
#  }
#
#   usb {
#     # This is a Sonoff ZigBee dongle
#     host = "10c4:ea60"
#   }
#
#   network {
#     model = "virtio"
#     bridge = "vmbr0"
#   }
#
#   sockets = 2
#   memory = 3072
# }
