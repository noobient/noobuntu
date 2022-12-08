FROM ubuntu:22.04

# Generic apt basics
RUN apt -y update
RUN apt -y dist-upgrade

# Allow for file downlodas
RUN apt -y install --no-install-recommends wget ca-certificates

# Install compiler tools
RUN apt -y install --no-install-recommends make gcc bc bison python3-minimal dwarves flex

# Install misc utilities
RUN apt -y install --no-install-recommends kmod bash libxml2-utils jq

# Install headers
RUN apt -y install --no-install-recommends libc6-dev libelf-dev libssl-dev

# For interactive menuconfig
RUN apt -y install --no-install-recommends libncurses-dev pkg-config

# Set up tool paths, if not using the default versions
#RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 10

# Install the kernel and the modules
RUN mkdir -p /usr/src/wsl-kernel
COPY build-kernel.sh /usr/src/wsl-kernel/build-kernel.sh

# Run the builder script
CMD /usr/src/wsl-kernel/build-kernel.sh
