#!/bin/bash

echo "[*] Updating system ..."
export DEBIAN_FRONTEND=noninteractive
sudo dpkg --add-architecture i386 # allow x86 arch packages 
sudo apt-get update -q

# Install reqs
echo "[*] Installing dependencies ..."
sudo apt-get install -q -y nodejs nasm gdb unzip p7zip-full openjdk-8-jre wget python2 python3 qemu-system-x86 git-core build-essential libc6-dev-i386-cross libc6-dev-i386 clang curl time python3-pip packer qemu-system kpartx qemu

# Install rust & rust toolchains/components/targets
echo "[*] Installing rust ..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH=$HOME/.cargo/bin:$PATH
rustup toolchain install stable
rustup target add wasm32-unknown-unknown
rustup component add rustfmt-preview