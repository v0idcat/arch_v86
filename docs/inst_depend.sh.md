#### 0. Script Overview
This script installs all dependencies required for the project. It reduces output messages and required user input by [modifying the `DEBIAN_FRONTEND` variable](https://askubuntu.com/questions/972516/debian-frontend-environment-variable), and using the `-q` flags to reduce `apt`'s output messages. 

The code is mostly taken from [this dockerfile](https://github.com/copy/v86/blob/b81df778019dd1fd43f7c813aad7266d30f626cb/tools/docker/test-image/Dockerfile), with modifications applied.