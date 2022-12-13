#!/bin/bash

docker run -it --rm --mount type=bind,source=/mnt/c,target=/c noobuntu/wsl-kernel
