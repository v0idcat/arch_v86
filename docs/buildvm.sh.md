#### 0. Script Overview
This script: 
1. uses [Packer](https://www.packer.io/) to build the Arch Linux image,
2. tests if building was a success, mounts the image, & map
3. Wraps up:
	1. Creates backup of file system
	2. unmounts image
	3. relocates image

---
#### 1. Packer image creation
Packer is a system and images builder that automates the process by using a set of configurations specified by the user to complete the entire setup. The original code for this script is from [this repo](https://github.com/vdloo/archlinux-v86-builder/). Modifications to the script were done with the help of [this readme file.](https://github.com/copy/v86/blob/master/docs/archlinux.md)

##### 1.1 Packer & `template.json`
To build the image, packer is launched right after the variables are set in the script. The launch command has an argument that provides access to the `packer/template.json` file, which specifies boot commands to run, boot wait time, disk size, ISO url & checksum, among many other things. 

Packer provides a [Qemu builder](https://developer.hashicorp.com/packer/plugins/builders/qemu), which we use in the `template.json` file to create the image.

Important things to note are:
- `"scripts": ["scripts/provision.sh"]`
	- Specifies the [shell provisioner](https://developer.hashicorp.com/packer/docs/provisioners/shell) for packer (Note that the one in use in this repo is utilizing `.json` format, not `.hcl2`)
- `"boot_wait": "4m30s"`
	- Specifies how long packer will wait before issuing commands to the VM. This is how long the VM will take *on my computer* to boot into the shell. If your PC is slower, you may have to increase the wait time until the boot sequence is complete. 
- `"iso_url": "<URL>"`
	- Specifies the URL to download the ISO image from. The sha1 checksum *must match the one provided to* `template.json`, *otherwise packer will refuse to continue.*
- [Full Packer documentation here.](https://developer.hashicorp.com/packer/docs)

##### 1.2 VM configuration & `provision.sh` 
The majority of code from `provision.sh` is taken from [this readme file.](https://github.com/copy/v86/blob/master/docs/archlinux.md) You may also find it helpful to review the [installation guide for Arch.](https://wiki.archlinux.org/title/Installation_guide) Differences from the default installation include (but not limited to) the kernel modules loaded for browser keyboard input support & the Plan 9 filesystem. 

Should you want to install more packages to your VM, you can do so by adding their names to line #31 of the `provision.sh` script.

---
#### 2. Testing, mounting & mapping
Code for this script was also taken from the readme specified in the previous section. 

Once packer is done, and the VM exists where we expect it to, `buildvm.sh` will continue by cleaning up any previous mount points, before mounting the image we just created. 

Once mounting is completed, [`fs2json.py`](https://github.com/copy/fs2json) ([new version here](https://github.com/copy/v86/blob/master/tools/fs2json.py)) is executed, which creates a JSON mapping of the entire filesystem. This is followed by [`copy-to-sha256.py`](https://github.com/copy/v86/blob/master/tools/copy-to-sha256.py), which creates the `.bin` files that are requested by clients when accessing the VM via the v86 project. 

---
#### 3. Wrapping up
Once everything is complete, it creates a backup of the filesystem, and sets ownership of the backup files to the current user. 

It continues wrapping up by unmounting the filesystem, cleaning the mount points, and moves the image to the directory `v86/images/`.