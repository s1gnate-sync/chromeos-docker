#!/usr/bin/env bash

set -eu

[ "$(id -u)" = "0" ] || {
    echo "${0}: must be root"
    exit 1
}

cd "$(dirname $(readlink -f $0))"


if ! ip addr show devtap &> /dev/null; then
    route_via() (
        local HOST_DEV="${1:-}"
        local NAME="${2:-}"
        iptables -t nat -A POSTROUTING -o "${HOST_DEV}" -j MASQUERADE
        iptables -A FORWARD -i "${HOST_DEV}" -o "${NAME}" -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i "${NAME}" -o "${HOST_DEV}" -j ACCEPT
    )

    add_tap_interface() (
        local NAME="${1:-}"
        local IP="${2:-}"
        local MASK="${3:-24}"
        ip link show dev "${NAME}" &> /dev/null || {
                ip tuntap add mode tap user chronos vnet_hdr "${NAME}"
                ip addr add "${IP}/${MASK}" dev "${NAME}"
                ip link set "${NAME}" up
                return 0
        }
        return 1
    )

    add_tap_interface devtap 192.168.10.1 && {
        route_via wlan0 devtap
        route_via eth0 devtap
    }

    sysctl net.ipv4.ip_forward=1
fi

crosvm run \
    --disable-sandbox \
    --cpus 4 \
    --mem 1024 \
    --net tap-name=devtap \
    --block "vm_state,o_direct=true,sparse=false" \
    --block "vm_root,ro,o_direct=true,root,sparse=false" \
    "vm_kernel"