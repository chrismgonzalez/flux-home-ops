#! bin/bash

##
# Run this script from within the console of your Proxmox server
##
set e

echo "creating cloud-init image"

apt update -y
apt install libguestfs-tools -y

wget https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-37-1.7.x86_64.qcow2

virt-customize -a Fedora-Cloud-Base-37-1.7.x86_64.qcow2 --install qemu-guest-agent
qm create 9000 --name "fedora-37-cloudinit" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 Fedora-Cloud-Base-37-1.7.x86_64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000

### Create a second template on the 2nd node

wget https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-37-1.7.x86_64.qcow2

virt-customize -a Fedora-Cloud-Base-37-1.7.x86_64.qcow2 --install qemu-guest-agent
qm create 9001 --name "fedora-37-cloudinit" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9001 Fedora-Cloud-Base-37-1.7.x86_64.qcow2 local-lvm
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
qm set 9001 --ide2 local-lvm:cloudinit
qm set 9001 --boot c --bootdisk scsi0
qm set 9001 --serial0 socket --vga serial0
qm set 9001 --agent enabled=1
qm template 9001


echo "next up, clone VM, then expand the disk"
echo "you also still need to copy ssh keys to the newly cloned VM"

## optional to test

# qm clone 9000 100 --name test-box
# qm set 100 --sshkey ~/.ssh/id_rsa.pub
# qm set 100 --ipconfig0 ip=192.168.0.100/24,gw=192.168.0.1
# qm start 100
