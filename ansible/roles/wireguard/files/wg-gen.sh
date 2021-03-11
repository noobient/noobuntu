#!/bin/bash

set -eu

export wg_root='/etc/wireguard'

. "${wg_root}/wg-gen.conf"

wg_int_net=$(awk -F. '{print $1 "." $2 "." $3}' <<< ${wg_ip})

function gen_keypair ()
{
    if [ ! -f "${1}/${2}.privkey" ]
    then
        wg genkey > "${1}/${2}.privkey" 2>/dev/null
    fi

    chmod 0600 "${1}/${2}.privkey"
    wg pubkey < "${1}/${2}.privkey" > "${1}/${2}.pubkey"
    chmod 0644 "${1}/${2}.pubkey"
}

function gen_psk ()
{
    if [ ! -f "${1}/${2}.psk" ]
    then
        wg genpsk > "${1}/${2}.psk"
    fi

    chmod 0600 "${1}/${2}.psk"
}

mkdir -p "${wg_root}/clients.d"
gen_keypair "${wg_root}" server

cat << EOF > "${wg_root}/wg0.conf"
[Interface]
PrivateKey = $(cat "${wg_root}/server.privkey")
Address = ${wg_int_net}.1/24
ListenPort = ${wg_port}

EOF

for (( i=1; i<=${wg_clients}; i++ ))
do
    gen_keypair "${wg_root}/clients.d" $((i+1))
    gen_psk "${wg_root}/clients.d" $((i+1))

    cat << EOF >> "${wg_root}/wg0.conf"
[Peer]
PublicKey = $(cat "${wg_root}/clients.d/$((i+1)).pubkey")
PresharedKey = $(cat "${wg_root}/clients.d/$((i+1)).psk")
AllowedIPs = ${wg_int_net}.$((i+1))/32
EOF

    cat << EOF > "${wg_root}/clients.d/$((i+1)).conf"
[Interface]
PrivateKey = $(cat "${wg_root}/clients.d/$((i+1)).privkey")
Address = ${wg_int_net}.$((i+1))/24
DNS = ${wg_dns}

[Peer]
PublicKey = $(cat "${wg_root}/server.pubkey")
PresharedKey = $(cat "${wg_root}/clients.d/$((i+1)).psk")
#AllowedIPs = 0.0.0.0/0
AllowedIPs = ${wg_int_net}.0/24
Endpoint = ${wg_endpoint}:${wg_port}
EOF

    chmod 0600 "${wg_root}/clients.d/$((i+1)).conf"
done
