provider "proxmox" {
  pm_api_url = "https://${var.proxmox_endpoint}:8006/api2/json"
  pm_user = "${var.pm_user}@${var.pm_realm}"
  pm_password = var.pm_password

  # TODO: This can be removed for prod, I assume?
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "docker_containers_vm" {
  for_each = toset(var.proxmox_cluster_nodes)

  name = "docker-containers-${each.key}-test"
  clone = "docker-containers-${each.key}-template"
  tags = "docker_containers"
  target_node = each.key

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
  ipconfig0 = "dhcp"
  agent = 1
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
  ipconfig0 = "dhcp"
  agent = 1
}
