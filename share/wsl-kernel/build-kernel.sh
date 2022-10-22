#!/bin/bash

export KERNEL_DIR='/c/wsl'

function enable_kernel_module ()
{
    sed -E -i "s/.*(${1})[ =]+.*/\1=m/g" .config
}

# TODO detect verion and path automatically
wget https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/rolling-lts/wsl/5.15.68.1.tar.gz
tar xf 5.15.68.1.tar.gz
cd WSL2-Linux-Kernel-rolling-lts-wsl-5.15.68.1

cat /proc/config.gz | gunzip > .config.stock
cp .config.stock .config
make olddefconfig

enable_kernel_module CONFIG_NF_CONNTRACK
enable_kernel_module CONFIG_NF_CONNTRACK_TFTP
enable_kernel_module CONFIG_NETFILTER_XT_MATCH_HELPER

# TODO add name to kernel name microsoft-kernel -> microsoft-noobuntu

make -j $(nproc)

mkdir -p "${KERNEL_DIR}"
INSTALL_PATH="${KERNEL_DIR}" make install
INSTALL_MOD_PATH="${KERNEL_DIR}" make modules_install

cd "${KERNEL_DIR}"
ln -sf vmlinuz-5.15.68.1-microsoft-standard-WSL2 vmlinuz
