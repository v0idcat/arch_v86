#!/bin/bash

if [ -z "$3" ]
    then
    echo "Insufficient arguments supplied."
    echo ""
    echo "Please supply the root directory of v86 project, the raw format image file, and the output dir to save"
    echo "the mappings to. Note that the output dir will contain arch/, and fs.json"
    echo ""
    echo ""
    echo "Usage: $0 <V86_ROOTDIR> <INPUT_IMAGE> <OUTPUT_DIR>"
    echo ""
    echo "Example: $0 /home/$(logname)/v86 /home/$(logname)/v86/images/arch.img /home/$(logname)/v86/images/arch"
    echo ""
    exit
fi

v86_loc=$1
input=$2
output=$3

if [[ "$output" == */ ]] # if last char == /
    then
    output=${output::-1} # remove last char
fi

mount_loc="$v86_loc"/diskmount

# clean up any previous loops and mounts
echo "[*] Making sure mountpoint is empty"
devloop=$(sudo losetup -f)

sudo umount "$mount_loc" -f || /bin/true
sudo kpartx -d "$devloop" || /bin/true
sudo losetup -d "$devloop" || /bin/true

# mount the generated raw image, we do that so we can create
# a json mapping of it and copy it to host on the webserver
mkdir -p "$mount_loc"
echo "[*] Mounting the created image so we can convert it to a p9 image"
sudo losetup "$devloop" "$input"
sudo kpartx -a "$devloop"
sudo mount /dev/mapper/"$(basename $devloop)"p1 "$mount_loc"

# make output dir if doesn't exist
mkdir -p "$output"
mkdir -p "$output"/arch

# clear dir if exists
sudo rm -rf "$output"/arch/*
sudo rm "$output"/fs.json

# map the filesystem to json with fs2json
sudo "$v86_loc"/tools/fs2json.py --out "$output"/fs.json "$mount_loc"
sudo "$v86_loc"/tools/copy-to-sha256.py "$mount_loc" "$output"/arch/

# copy the filesystem and chown to nonroot user
sudo chown -R "$(logname)":"$(logname)" "$output"

# clean up mount
echo "[*] Cleaning up mounts"
sudo umount "$mount_loc" -f
rm -rf "$mount_loc"
sudo kpartx -d "$devloop"
sudo losetup -d "$devloop"