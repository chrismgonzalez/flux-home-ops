###################### commands ###########################
# terraform apply -auto-approve -lock=false -parallelism=2
###########################################################
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.9"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }

  backend "s3" {
    region         = "us-east-2"
    bucket         = "homeops-dev-use2-terraform-backend"
    key            = "homeops/proxmox/terraform.tfstate"
    dynamodb_table = "terraform-lock"
    role_arn       = "arn:aws:iam::403612620603:role/terraform-backend"
    encrypt        = true
  }
}

data "sops_file" "proxmox_secrets" {
  source_file = "secret.sops.yaml"
}

provider "proxmox" {
  alias      = "echo"
  pm_api_url = data.sops_file.proxmox_secrets.data["pm_api_url_echo"]
  # pm_api_token_id     = data.sops_file.proxmox_secrets.data["pm_api_token_id"]
  # pm_api_token_secret = data.sops_file.proxmox_secrets.data["pm_api_token_secret"]
  pm_user     = data.sops_file.proxmox_secrets.data["pm_user"]
  pm_password = data.sops_file.proxmox_secrets.data["pm_password"]
  # leave tls_insecure set to true unless you have your proxmox SSL certificate situation fully sorted out (if you do, you will know)
  pm_tls_insecure = true
}

provider "proxmox" {
  alias      = "jocko"
  pm_api_url = data.sops_file.proxmox_secrets.data["pm_api_url_jocko"]
  # pm_api_token_id     = data.sops_file.proxmox_secrets.data["pm_api_token_id"]
  # pm_api_token_secret = data.sops_file.proxmox_secrets.data["pm_api_token_secret"]
  pm_user     = data.sops_file.proxmox_secrets.data["pm_user"]
  pm_password = data.sops_file.proxmox_secrets.data["pm_password"]
  # leave tls_insecure set to true unless you have your proxmox SSL certificate situation fully sorted out (if you do, you will know)
  pm_tls_insecure = true
}

locals {
  echo = {
    1 = {
      vmid       = 101
      ip_address = "10.10.10.81"
    }
    3 = {
      vmid       = 103
      ip_address = "10.10.10.83"
    }
    4 = {
      vmid       = 104
      ip_address = "10.10.10.84"
    }
  }

  jocko = {
    2 = {
      vmid       = 102
      ip_address = "10.10.10.82"
    }
    5 = {
      vmid       = 105
      ip_address = "10.10.10.85"
    }
    6 = {
      vmid       = 106
      ip_address = "10.10.10.86"
    }
  }
}

variable "template_name" {
  default = "ubuntu-2004-cloudinit"
}
resource "proxmox_vm_qemu" "k3s-masters" {
  provider = proxmox.echo

  for_each = local.echo

  name        = "k3s-${each.key}"
  target_node = "echo"
  full_clone  = true
  clone       = var.template_name
  vmid        = each.value.vmid
  agent       = 1
  os_type     = "cloud-init"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  ciuser     = "serveradmin"
  cipassword = "serveradmin"
  ipconfig0  = "ip=${each.value.ip_address}/24,gw=10.10.10.1"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = data.sops_file.proxmox_secrets.data["ssh_key"]


  disk {
    slot     = 0
    size     = "20G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

resource "proxmox_vm_qemu" "k3s-workers" {
  for_each = local.jocko

  provider    = proxmox.jocko
  name        = "k3s-${each.key}"
  target_node = "jocko"

  full_clone = true
  clone      = var.template_name
  vmid       = each.value.vmid

  agent    = 1
  os_type  = "cloud-init"
  cores    = 2
  sockets  = 1
  cpu      = "host"
  memory   = 4096
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  ciuser     = "serveradmin"
  cipassword = "serveradmin"
  ipconfig0  = "ip=${each.value.ip_address}/24,gw=10.10.10.1"

  sshkeys = data.sops_file.proxmox_secrets.data["ssh_key"]

  disk {
    slot     = 0
    size     = "20G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  depends_on = [
    proxmox_vm_qemu.k3s-masters
  ]
}
