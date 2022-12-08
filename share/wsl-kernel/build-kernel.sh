#!/bin/bash

export WSL_DIR='/c/wsl'
export KERNEL_DIR="${WSL_DIR}/new"

# Apparently these work even as builtins after all
loadables=(
#    CONFIG_NF_CONNTRACK_TFTP
#    CONFIG_NF_NAT_TFTP
)

builtins=(
    CONFIG_NETFILTER_XT_TARGET_CT
    CONFIG_NETFILTER_XT_MATCH_HELPER
)

# Let these stay here until 22.04 is also sorted out
# Reference: https://cateee.net/lkddb/web-lkddb/
#CONFIG_IP_NF_TARGET_REJECT
#CONFIG_NF_CONNTRACK
#CONFIG_IP_NF_IPTABLES
#CONFIG_NF_REJECT_IPV4
#CONFIG_IP6_NF_IPTABLES
#CONFIG_NET_SCH_FQ_CODEL
#CONFIG_BPFILTER_UMH
#CONFIG_IP_SET
#CONFIG_NETFILTER_NETLINK
#CONFIG_NF_REJECT_IPV6
#CONFIG_NF_TABLES
#CONFIG_NFT_COUNTER
#CONFIG_NETFILTER_XTABLES

function enable_module ()
{
    echo "Enabling ${1} (${2})"
    sed -E -i "s@.*(${1})[ =]+.*@\1=${2}@g" .config
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
make olddefconfig

for module in ${loadables[@]}
do
    enable_module "${module}" 'm'
done

for module in ${builtins[@]}
do
    enable_module "${module}" 'y'
done

sed -E -i 's@^(CONFIG_LOCALVERSION)=.*@\1="-microsoft-noobuntu-WSL2"@' .config

make -j $(nproc)

mkdir -p "${KERNEL_DIR}"
INSTALL_PATH="${KERNEL_DIR}" make install
INSTALL_MOD_PATH="${KERNEL_DIR}" make modules_install

cd "${KERNEL_DIR}"
ln -sf "vmlinuz-${WSL_VER}-microsoft-noobuntu-WSL2" vmlinuz
