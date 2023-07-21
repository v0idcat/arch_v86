#!/bin/bash

SRC="$1"/rsrc/packer/
V86_ROOT="$1"/v86

# build the boxfile from the iso in subshell
(cd "$SRC" && sudo PACKER_LOG=1 PACKER_LOG_PATH="./packer.log" packer build -force template.json)

# test if there is a boxfile where we expected it
if [ ! -f "$SRC"/output-qemu/Briareus ]; then
    echo "[-] Looks like something went wrong building the image, maybe try again?"
    exit 1
fi;

# clean up previous loops and mounts
echo "[*] Making sure mountpoint is empty"
devloop=$(sudo losetup -f)

sudo umount diskmount -f || /bin/true
sudo kpartx -d "$devloop" || /bin/true
sudo losetup -d "$devloop" || /bin/true

# mount the generated raw image, we do that so we can create
# a json mapping of it and copy it to host on the webserver
mkdir -p diskmount
echo "[*] Mounting the created image so we can convert it to a p9 image"
sudo losetup "$devloop" "$SRC"/output-qemu/Briareus
sudo kpartx -a "$devloop"
sudo mount /dev/mapper/$(basename $devloop)p1 diskmount

# make images dir in v86 folder
mkdir -p "$V86_ROOT"
mkdir -p "$V86_ROOT"/images
mkdir -p "$V86_ROOT"/images/arch

# map the filesystem to json with fs2json
sudo "$V86_ROOT"/tools/fs2json.py --out "$V86_ROOT"/images/fs.json diskmount
sudo "$V86_ROOT"/tools/copy-to-sha256.py diskmount "$V86_ROOT"/images/arch

# copy the filesystem and chown to nonroot user
echo "[*] Creating a backup at $V86_ROOT/bkup/arch"
mkdir "$V86_ROOT"/bkup/arch -p
sudo rsync -q -av diskmount/ "$V86_ROOT"/bkup/arch
sudo chown -R $(logname):$(logname) "$V86_ROOT"/bkup/arch

# clean up mount
echo "[*] Cleaning up mounts"
sudo umount diskmount -f
sudo rm -rf diskmount
sudo kpartx -d "$devloop"
sudo losetup -d "$devloop"

# Move the image to the images dir
sudo mv "$SRC"/output-qemu/Briareus "$V86_ROOT"/images/arch.img