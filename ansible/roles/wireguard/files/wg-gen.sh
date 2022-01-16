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

function parse_users ()
{
    do_users=0
    if [ ! -z ${wg_users+x} ]
    then
        IFS=',' wg_users_arr=( ${wg_users} )
        if [ ${wg_clients} -eq ${#wg_users_arr[@]} ]
        then
            do_users=1
        fi
    fi
}

function print_users ()
{
    if [ ${do_users} -eq 1 ]
    then
        for (( i=0; i<${wg_clients}; i++ ))
        do
            echo ${wg_users_arr[i]}
        done
    fi
}

function symlink_users ()
{
    if [ ${do_users} -eq 1 ]
    then
        pushd "${wg_root}/clients.d" > /dev/null

        for (( i=0; i<${wg_clients}; i++ ))
        do
            ln -s -f "$((i+2)).conf" "${wg_users_arr[i]}.conf"
        done

        popd > /dev/null
    fi
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
PersistentKeepalive = 30
EOF

    chmod 0600 "${wg_root}/clients.d/$((i+1)).conf"
done

parse_users
symlink_users

systemctl restart wg-quick@wg0.service
