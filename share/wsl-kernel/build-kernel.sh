#!/bin/sh

# TODO detect verion and path automatically
wget https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/rolling-lts/wsl/5.15.68.1.tar.gz
tar xf 5.15.68.1.tar.gz
cd WSL2-Linux-Kernel-rolling-lts-wsl-5.15.68.1

cat /proc/config.gz | gunzip > .config
make olddefconfig
sed -E -i.stock 's/.*(CONFIG_NETFILTER_XT_MATCH_HELPER).*/\1=y/g' .config

make -j $(nproc)
cp arch/x86/boot/bzImage /c/temp/wsl-conntrack.kernel
