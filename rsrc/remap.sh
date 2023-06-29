#!/bin/bash

DIR=/home/"$(logname)"/Documents/arch_v86

# clean up any previous loops and mounts
echo "[*] Making sure mountpoint is empty"
devloop=$(sudo losetup -f)

sudo umount diskmount -f || /bin/true
sudo kpartx -d "$devloop" || /bin/true
sudo losetup -d "$devloop" || /bin/true

# mount the generated raw image, we do that so we can create
# a json mapping of it and copy it to host on the webserver
mkdir -p diskmount
echo "[*] Mounting the created image so we can convert it to a p9 image"
sudo losetup "$devloop" "$DIR"/v86/images/arch.img
sudo kpartx -a "$devloop"
sudo mount /dev/mapper/$(basename $devloop)p1 diskmount

# make images dir if doesn't exist
mkdir -p "$DIR"/v86/images
mkdir -p "$DIR"/v86/images/arch

# clear dir if exists
sudo rm -rf "$DIR"/v86/images/arch/*
sudo rm "$DIR"/v86/images/fs.json

# map the filesystem to json with fs2json
sudo "$DIR"/v86/tools/fs2json.py --out "$DIR"/v86/images/fs.json diskmount
sudo "$DIR"/v86/tools/copy-to-sha256.py diskmount "$DIR"/v86/images/arch

# copy the filesystem and chown to nonroot user
echo "[*] Creating a backup at $DIR/v86/bkup/arch"
mkdir "$DIR"/v86/bkup/arch -p
sudo rsync -q -av diskmount/ "$DIR"/v86/bkup/arch
sudo chown -R $(logname):$(logname) "$DIR"/v86/bkup/arch

# clean up mount
echo "[*] Cleaning up mounts"
sudo umount diskmount -f
sudo kpartx -d "$devloop"
sudo losetup -d "$devloop"