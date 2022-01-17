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
    if [ ${do_users} -ne 1 ]
    then
        return
    fi

    for (( i=0; i<${wg_clients}; i++ ))
    do
        echo ${wg_users_arr[i]}
    done
}

function publish_config ()
{
    if [ ${do_users} -ne 1 ]
    then
        return
    fi

    pushd "${wg_root}/repo.d" > /dev/null
    git reset --hard > /dev/null

    for (( i=0; i<${wg_clients}; i++ ))
    do
        \cp -f "${wg_root}/clients.d/$((i+2)).conf" "${wg_users_arr[i]}.conf"
        \cp -f "${wg_root}/clients.d/$((i+2)).png" "${wg_users_arr[i]}.png"
    done

    git add -A
    date_str=$(date +%Y%m%d-%H%M%S)
    git diff-index --quiet HEAD || git commit -m "Generated config ${date_str}"
    git push -f

    popd > /dev/null
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
Endpoint = ${wg_endpoint}:${wg_port}
PersistentKeepalive = 30
EOF

    case ${wg_tunnel} in
        split)
            echo "AllowedIPs = ${wg_int_net}.0/24" >> "${wg_root}/clients.d/$((i+1)).conf"
            ;;

        full)
            echo "AllowedIPs = 0.0.0.0/0" >> "${wg_root}/clients.d/$((i+1)).conf"
            ;;

        *)
            echo "Error! Invalid tunnel type: ${wg_tunnel}"
            exit 1

    esac

    qrencode -t PNG -r "${wg_root}/clients.d/$((i+1)).conf" -o "${wg_root}/clients.d/$((i+1)).png"
    chmod 0600 "${wg_root}/clients.d/$((i+1)).conf"
    chmod 0600 "${wg_root}/clients.d/$((i+1)).png"
done

parse_users
publish_config

systemctl restart wg-quick@wg0.service
