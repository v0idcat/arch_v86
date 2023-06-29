#!/bin/bash
# 
# This script installs all requirements for v86 project
# and downloads and installs v86 project on your local machine
# as well as creating an Arch Linux image.
# 
# Tested on Ubuntu 22.04

if ! [ "$EUID" -ne 0 ]
    then echo ""
    echo "[-] Please do not run this script with sudo, as"
    echo "    that will interfere with file ownerships!"
    echo "    It's designed to automatically ask for "
    echo "    permissions only when necessary."
    echo ""
    exit
fi

USER="$(logname)"
DIR=/home/"$USER"/Documents/arch_v86

# Update sys
echo "==================================="
echo "=== [*] Installing dependencies ==="
echo "==================================="
cd "$DIR" && /bin/bash ./rsrc/inst_depend.sh

# provide rust to current shell
export PATH=$HOME/.cargo/bin:$PATH

# Fetch & build v86 project
echo "======================================"
echo "=== [*] Downloading & building v86 ==="
echo "======================================"
cd "$DIR" && git clone https://github.com/copy/v86
cd "$DIR"/v86/ && make all

# relocate remap.sh and make it executable
mv "$DIR"/rsrc/remap.sh "$DIR"/v86/tools/remap.sh && chmod +x "$DIR"/v86/tools/remap.sh

# Build VM
echo "================================================="
echo "=== [*] Downloading & building the arch image ==="
echo "================================================="
cd "$DIR"/rsrc && sudo /bin/bash "$DIR"/rsrc/buildvm.sh
sed -i 's/\"init=\/usr\/bin\/init-openrc\",//g' "$DIR"/v86/examples/arch.html

# Fetching RangeHTTPServer
wget https://raw.githubusercontent.com/smgoller/rangehttpserver/master/RangeHTTPServer.py -P "$DIR"/v86/tools/

# Set appropriate ownership
sudo chown -R "$USER":"$USER" "$DIR"

echo ""
echo ""
echo "[+] All installations complete. To continue, don't forget to run the following"
echo "             command to make rust accessible in this shell: "
echo "                   source \"$HOME/.cargo/env\""
echo ""