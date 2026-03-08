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
  clone = "debian-base-template"
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

  dynamic "pcis" {
    for_each = startswith(each.key, "zotac") ? toset([1]) : toset([])

    content {
      pci0 {
        raw {
          raw_id = "0000:01:00.0"
        }
      }
    }
  } 

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  cpu {
    sockets = 4
  }

  memory = 12288
  ipconfig0 = "ip=dhcp"
  agent = 1
}

resource "proxmox_vm_qemu" "dev_playground_vm" {
  name = "dev-playground"
  clone = "debian-base-template"
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
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  cpu {
    sockets = 2
  }

  memory = 2048
  ipconfig0 = "ip=dhcp"
  agent = 1
}

output "docker_containers_ips" {
  description = "The IPs of the k3s nodes created"
  value = {
    for node, machine in proxmox_vm_qemu.docker_containers_vm : node => machine.default_ipv4_address
  }
}

output "dev_playground_ips" {
  description = "The IPs of the dev playground created"
  value = proxmox_vm_qemu.dev_playground_vm.default_ipv4_address
}