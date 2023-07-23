#!/usr/bin/env bash

cd "$(dirname $0)"
source include/common.inc

for container in $(lxc ls -c n -f csv | grep "${INSTANCE_PREFIX}"); do
    echo "deleting build instance ${container}"
    lxc delete --force "${container}" 2> /dev/null || true
done

[ -e "${BUILD_DIR}" ] && for file in $(ls -1 "${BUILD_DIR}"); do 
    file="${BUILD_DIR}/${file}"
    echo "deleting build artifact ${file}"
    mountpoint -q "${file}" && umount "${file}"
    rm -fr "${file}" 2> /dev/null || true
done

[ "${1:-}" = "--all" ] && {
    echo "deleting cache ${CACHE_KEY}"
    lxc delete --force "${CACHE_KEY}" &> /dev/null || true
}
