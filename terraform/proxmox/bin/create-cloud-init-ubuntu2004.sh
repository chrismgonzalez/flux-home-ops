#! bin/bash

##
# Run this script from within the console of your Proxmox server
##
set e

echo "creating cloud-init image"

apt update -y
apt install libguestfs-tools -y

wget https://cloud-images.ubuntu.com/focal/20230105/focal-server-cloudimg-amd64.img

virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
qm create 9000 --name "ubuntu-2004-cloudinit" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000


## optional to test

# qm clone 9000 100 --name test-box
# qm set 100 --sshkey ~/.ssh/id_rsa.pub
# qm set 100 --ipconfig0 ip=192.168.0.100/24,gw=192.168.0.1
# qm start 100
