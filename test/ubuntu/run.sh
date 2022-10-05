#!/bin/bash

docker run -it --rm --mount type=bind,source="$(pwd)"/../..,target=/noobuntu  noobuntu-ubuntu2204
