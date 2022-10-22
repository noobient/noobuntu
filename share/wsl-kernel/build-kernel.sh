#!/bin/bash

export KERNEL_DIR='/c/wsl'

function enable_kernel_module ()
{
    sed -E -i "s@.*(${1})[ =]+.*@\1=m@g" .config
}

REL_PAGE='https://github.com/microsoft/WSL2-Linux-Kernel/releases/latest'
wget -O release.html "${REL_PAGE}"
WSL_VER=$(xmllint --html --nowarning --xpath '/html/head/title/text()' release.html 2>/dev/null | awk '{print $2}' | cut -d'/' -f3)
REL_URL="https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/rolling-lts/wsl/${WSL_VER}.tar.gz"

wget -O wsl.tgz "${REL_URL}"
tar xf wsl.tgz
cd "WSL2-Linux-Kernel-rolling-lts-wsl-${WSL_VER}"

cat /proc/config.gz | gunzip > .config.stock
cp .config.stock .config
make olddefconfig

enable_kernel_module CONFIG_NF_CONNTRACK
enable_kernel_module CONFIG_NF_CONNTRACK_TFTP
enable_kernel_module CONFIG_NETFILTER_XT_MATCH_HELPER

sed -E -i 's@^(CONFIG_LOCALVERSION)=.*@\1="-microsoft-noobuntu-WSL2"@' .config

make -j $(nproc)

mkdir -p "${KERNEL_DIR}"
INSTALL_PATH="${KERNEL_DIR}" make install
INSTALL_MOD_PATH="${KERNEL_DIR}" make modules_install

cd "${KERNEL_DIR}"
ln -sf "vmlinuz-${WSL_VER}-microsoft-noobuntu-WSL2" vmlinuz
