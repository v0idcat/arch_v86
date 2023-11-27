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

if [ -z "$1" ]
    then echo "Insufficient arguments. Please supply the installation directory."
    echo ""
    echo ""
    echo "Usage: $0 <OUTPUT>"
    echo "Example: $0 /var/www/html/web_arch"
    echo ""
    exit
fi

USER="$(logname)"
# fetch setup.sh directory
ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
OUTPUT=$1

if [[ "$OUTPUT" == */ ]] # if last char == /
    then
    OUTPUT=${OUTPUT::-1} # remove last char
fi

# Update sys
echo "==================================="
echo "=== [*] Installing dependencies ==="
echo "==================================="
cd "$ROOT_DIR" && /bin/bash ./rsrc/inst_depend.sh

# provide rust to current shell
export PATH=$HOME/.cargo/bin:$PATH

# Fetch & build v86 project
echo "======================================"
echo "=== [*] Downloading & building v86 ==="
echo "======================================"
sudo git clone https://github.com/copy/v86 && sudo sudo chown -R "$USER":"$USER" v86 && cd v86/ && make all && cd ..

# relocate remap.sh and make it executable
mv "$ROOT_DIR"/rsrc/remap.sh "$ROOT_DIR"/v86/tools/remap.sh && chmod +x "$ROOT_DIR"/v86/tools/remap.sh

# Build VM
echo "================================================="
echo "=== [*] Downloading & building the arch image ==="
echo "================================================="
sudo /bin/bash "$ROOT_DIR"/rsrc/buildvm.sh "$ROOT_DIR"
sed -i 's/\"init=\/usr\/bin\/init-openrc\",//g' "$ROOT_DIR"/v86/examples/arch.html

# Fetching RangeHTTPServer
#wget https://raw.githubusercontent.com/smgoller/rangehttpserver/master/RangeHTTPServer.py -P "$ROOT_DIR"/v86/tools/
pip install rangehttpserver


# make dir if doesn't exist then move to output dir
# Set appropriate ownership
sudo mkdir -p "$OUTPUT"
sudo mv "$ROOT_DIR"/v86 "$OUTPUT"
sudo chown -R "$USER":"$USER" "$OUTPUT"

echo ""
echo ""
echo "[+] All installations complete. To continue, don't forget to run the following"
echo "             command to make rust accessible in this shell: "
echo "                   source \"$HOME/.cargo/env\""
echo ""