## Overview

This collection of scripts will build an [Arch Linux 32](https://archlinux32.org/) image using [Packer](https://www.packer.io/) with 9pfs specifically to be used with the [v86](https://github.com/copy/v86) project. This project builds upon [archlinux-v86-builder](https://github.com/vdloo/archlinux-v86-builder). The configuration allows for on-the-fly filesystem loading which will significantly reduce load times as well as bandwidth usage.

This project aims to streamline the entire set up as much as possible; it will install all dependencies, set up all configurations, and create the necessary links to have a basic Arch Linux installation ready to go on the v86 project that will be accessible at `examples/arch.html`. 

## Installation

*Tested on Ubuntu 22.04*

1. Run [`setup.sh`](docs/setup.sh.md) `<OUTPUT_DIR>` to install the project under the specified directory.
2. Inside the newly created `v86` directory, run [`python2 tools/RangeHTTPServer.py`](https://github.com/smgoller/rangehttpserver/) to host the files.

Note that while this script will require you to not run it with `sudo` privileges, the current user still needs to be able to issue `sudo` commands.

Below you will find information pertaining to how everything is set up, and how you may modify certain aspects of this project, including the arch image, to fit your needs. 

## General Information & Process Breakdown



#### \[ \* \] Overall process flow

[`setup.sh`](docs/setup.sh.md):
1. Calls [`rsrc/inst_depend.sh`](docs/inst_depend.sh.md)
	1. Updates system
	2. Installs dependencies
2. Builds v86
3. Calls [`rsrc/buildvm.sh`](docs/buildvm.sh.md):
	1. Builds VM using Packer
	2. Maps VM fs
4. Fetches RangeHTTPServer
5. Sets user ownership

---

#### \[ \* \] Installing Dependencies

The `setup.sh` file will install all dependencies required for this project to work by calling `inst_depend.sh`. That script will start by updating the system, then `sudo` installing all the dependencies. Then, it installs `rust` for *the current user only*, and as such, requires that these commands be issued by the current user, without sudo privileges. For this reason, `setup.sh` must **not** be ran with `sudo`.

---

#### \[ \* \] Building v86

This part is pretty straightforward; we'll be using the `examples/arch.html` file to boot the VM via the browser. The `setup.sh` script will run a couple commands to automate that process by `git clone`'ing the v86 project, then `make all` as the current user. This ensures that rust is present for the build process to succeed. 

---

#### \[ \* \] Building the image

The Arch Linux image is built using the [Qemu Packer](https://developer.hashicorp.com/packer/plugins/builders/qemu) builder tool, where the process is automated completely from bootloader installation & configuration to filesystem setup. 

The `rsrc/buildvm.sh` is the main script that will first launch `packer` to create the image.

`packer` will utilize the `rsrc/packer/template.json` configuration file to download, boot up Arch Linux and do preliminary setup, after which it will connect to the launched VM using SSH and use the `rsrc/packer/scripts/provision.sh` script to set up the image via SSH completely. 

Once that is done, execution returns to the `buildvm.sh` script, which checks if the image creation was successful. Then, it gets to work on mapping the image filesystem and creating compatible `.bin` files in the `output/images/arch/` directory that v86 will use to load the VM. 

Execution is then handed back to `setup.sh` at this point, where the built image is linked to the v86 project.

*NOTE:* If you are having issues with qemu packer connecting via SSH, try checking the boot up process by connecting to the Arch Installation VM via VNC. The local port should be given to you by packer/qemu before it waits for boot. This issue will arise if the boot_wait is not enough; in that case, you can increase the wait time in the file `rsrc/packer/scripts/template.json` Line #22.

---

#### \[ \* \] Running Arch in a BBVM

The image building process should automatically be mapped and linked to the necessary files required to load the VM. This section, however, will outline the simple process. In the `arch.html` file, you'll find the following lines that show the filesystem location: 
- `filesystem: { baseurl: "../images/arch/", basefs: "../images/fs.json"}` 

The `baseurl` contains the actual `.bin` files, while the `fs.json` contains the fs mapping data.

To run the project, we need to host the files using an HTTP server that supports the Range request; this server should already be downloaded by `setup.sh` to the `v86/tools/` folder. To start hosting, make sure you are in the base v86 directory, then run the command `python2 tools/RangeHTTPServer.py`.

Now we can go to `http://localhost:8000/examples/arch.html` and the VM will automagically boot.

---

#### \[ \* \] Saving/loading machine state

*Saving and loading states must be done through the v86 project.* 

You can save the machine state at anytime from `examples/arch.html` by pressing the `Save state to file` button at the top left corner of the webpage. This will save the current state in a `v86state.bin` file that can be loaded into v86 in the future at any time by using the `Browse...` button. 

If you want to automatically load a specified machine state when the webpage loads, move the downloaded `.bin` file to `images/` directory and modify the `examples/arch.html` file as follows:
- Change `bzimage_initrd_from_filesystem: true,` to `false`
- Add the line `initial_state: { "url": "http://localhost:8000/images/v86state.bin" },`
The next time you visit the same webpage, it should automatically load the machine state.

---

#### \[ \* \] Modifying the Arch image via Qemu

If you want to modify the base image, you can launch the `arch.img` file under `arch_v86/v86/images/` directory via qemu using the following command:
-  `qemu-system-x86-64 -m 0.5G -drive file=images/arch.img,format=raw` 

After you're done modifying the image, shutdown then run [`tools/remap.sh`](docs/remap.sh.md) to remap and recreate the `.bin` files that v86 uses to load the VM. This means that `arch.img` does not directly interact with v86, and as such, any modifications to that file will **not** transfer over until you run the script. 

---

#### \[ \* \] Hosting the project on Apache

Apache natively accepts range requests, which are required for this project to run properly. As such, there is no additional setup required beyond that of the Apache server itself. Once that's complete, you can place the `v86` folder inside the `/var/www/html/` folder so that users may access the VM. 