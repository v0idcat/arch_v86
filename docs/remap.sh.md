#### 0. Script Overview
This script aims to streamline the remapping of `.bin` files used by v86 created from the original image. It takes in 3 arguments:
1. `V86_ROOTDIR`
	1. The root directory of the installed v86 project
2. `INPUT_IMAGE`
	1. The image file to be mapped
3. `OUTPUT_DIR`
	1. The output directory - **NOTE:** The output directory *will be cleared of any previous files*. 

The output directory should be the same location that the old mappings were in, but the user can also choose any output directory they would like. This gives them the flexibility of having several different versions of the arch image available on the server, where each can be manually linked in separate web pages. 

Code from this script was adapted from the [setup.sh](../setup.sh) script.