#### 0. Script Overview
The `setup.sh` file is the primary installation script. It will: 
1. Run a few checks, then runs `rsrc/inst_depend.sh` script, which installs dependencies,
2. build the v86 project,
3. run `rsrc/buildvm.sh`, which builds the VM
4. wraps up installation and sets appropriate permissions

---
#### 1. - Checks and dependencies installation
##### 1.1 - `sudo` & arguments check
The first thing this script does is check the running EUID, and if it's `0`, it immediately `echo`s a warning, then exits. This is done so that all scripts that are launched (such as `inst_depend.sh`) have the appropriate privileges required for the installation. The biggest issue when ignoring these privileges is the rust installation, as it must be installed under the *current user's home directory*, and not `root`. 

Afterwards, an argument check occurs, which ensures that an argument has been supplied to the script. Once that is confirmed, it removes a `/` if it exists at the end of the argument, to conform with the script commands. Finally, it creates the directory, if it doesn't exist already.

##### 1.2 - Variables
The first variable, `$USER`, specifies which user will own the project's files and directories. This should be the same user as the one running the `setup.sh` script, as they need to have access to the rust installation.

There's 2 directories variables in use throughout the script, the current directory, `$ROOT_DIR`, [where the `setup.sh` is located](https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script), and the output directory, `$OUTPUT`, which is also the first argument. 

`setup.sh`'s directory is used as a preliminary installation directory due to the usage of other scripts that accompany this, such as `buildvm.sh`. The installation process will first install everything under the `setup.sh` directory, and then move it to the output directory.

##### 1.3 - Dependencies installation
All dependencies are installed with the `inst_depend.sh` script, which is called by `setup.sh`. After that script ends, execution returns to `setup.sh` Rust is provided to `setup.sh`'s shell by the `export` command. This allows it to build the v86 project without launching a new shell. 

---
#### 2. - Building v86
The v86 project is cloned into the directory where `setup.sh` is and built using the `make all` command. `setup.sh` will exit the `v86` directory after building, to access the `rsrc/` directory for future commands. 

After v86 is built, `remap.sh` is moved to the `v86/tools/` directory, with the correct permissions set.

---
#### 3. - Building the Arch VM
`rsrc/buildvm.sh` script is called with `sudo` privileges, and the `$ROOT_DIR` variable supplied as an argument; this will be used by the script as the installation directory for the VM. 

The following `sed` command removes the line `"init=/usr/bin/init-openrc",` from the `v86/examples/arch.html` file, within the `cmdline: [ ]` section. This line tells v86 to boot the arch image with OpenRC, which we do **not** want, as the image is not configured for it. If this line is retained, v86 will not be able to boot the VM. 

---
#### 4. - Wrapping up
Once v86 is built and the VM is configured, `setup.sh` will fetch a python HTTP server capable of supporting [range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) and save it within the `v86/tools/` directory. This python server is what will be used to host the project.

The script will then create the directory specified in `$OUTPUT`, move the v86 project to it, then set the permissions to the current user. Finally, it will output that installation is complete, and remind the user to make rust accessible to the current shell. 