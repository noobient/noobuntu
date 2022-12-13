#!/bin/bash

set -eu

export WSL_DIR='/c/wsl'
export KERNEL_DIR="${WSL_DIR}/new"
export SRC_DIR='/usr/src/wsl-kernel'

source "${SRC_DIR}/kernel.conf"

function enable_module ()
{
    # Make sure it works even if it's completely missing from the file due to
    # dependencies not being fulfilled.
    MATCH=0
    grep "${1}['='/' is not set']" .config > /dev/null && MATCH=1 || true

    if [ ${MATCH} -eq 1 ]
    then
        sed -E -i "s@.*(${1})[ =]+.*@\1=${2}@g" .config
        echo "Enabling ${1} (${2})"
    else
        echo "${1}=${2}" >> .config
        echo "Adding ${1} (${2})"
    fi
}

REL_PAGE='https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest'
REL_FILE='release.html'
wget -O "${REL_FILE}" "${REL_PAGE}"

# This only applied to that "rolling" 5.15.68.1 release we'll prolly never see again
#export WSL_VER=$(xmllint --html --nowarning --xpath '/html/head/title/text()' release.html 2>/dev/null | awk '{print $2}' | cut -d'/' -f3) # '
#export REL_URL="https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/rolling-lts/wsl/${WSL_VER}.tar.gz"
#export CANON_REL="WSL2-Linux-Kernel-rolling-lts-wsl-${WSL_VER}"

export CANON_REL=$(jq -r '.tag_name' "${REL_FILE}")
export REL_URL=$(jq -r '.tarball_url' "${REL_FILE}")
export WSL_VER="${CANON_REL##*-}" # trim anything before the last '-'

if [ -f "${WSL_DIR}/${CANON_REL}.tar.gz" ]
then
    # Unsure about performance so let's copy first
    cp "${WSL_DIR}/${CANON_REL}.tar.gz" wsl.tgz
else
    wget -O wsl.tgz "${REL_URL}"
fi

tar xf wsl.tgz
cd microsoft-WSL2-Linux-Kernel-*

# This won't work if you're already on a modified kernel
#cat /proc/config.gz | gunzip > .config.stock
cp Microsoft/config-wsl .config.stock
cp .config.stock .config

for module in ${loadables[@]}
do
    enable_module "${module}" 'm'
done

for module in ${builtins[@]}
do
    enable_module "${module}" 'y'
done

make olddefconfig

sed -E -i 's@^(CONFIG_LOCALVERSION)=.*@\1="-microsoft-noobuntu-WSL2"@' .config

make -j $(nproc)

mkdir -p "${KERNEL_DIR}"
INSTALL_PATH="${KERNEL_DIR}" make install

if [ ${#loadables[@]} -gt 0 ]
then
    # Depmod is really slow on WSL, skip if possible
    INSTALL_MOD_PATH="${KERNEL_DIR}" make modules_install
fi

cd "${KERNEL_DIR}"
ln -sf "vmlinuz-${WSL_VER}-microsoft-noobuntu-WSL2" vmlinuz
