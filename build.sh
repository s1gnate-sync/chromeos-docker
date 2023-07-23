#!/usr/bin/env bash

set -eu

source "$(dirname $0)/include/common.inc"

lxc ls | grep -q "${CACHE_KEY}" || {
    echo "building ${CACHE_KEY} container"

    trap "lxc delete --force ${CACHE_KEY}" ERR HUP INT TERM

    lxc init "images:ubuntu/jammy" "${CACHE_KEY}" \
        -c security.privileged=true -c security.nesting=true

    printf "lxc.cgroup2.devices.allow = b 259:* rw\nlxc.cgroup.devices.allow = b 259:* rw" \
        | lxc config set "${CACHE_KEY}" raw.lxc -

    {
        lxc config show "${CACHE_KEY}" | sed "/devices:/d"
        source "${PREFIX}/include/generate-loop-devices-config.inc"
    } | lxc config edit "${CACHE_KEY}"

    lxc start "${CACHE_KEY}"

    cat "${PREFIX}/include/distrobuild-script" | lxc exec "${CACHE_KEY}" -- sh

    lxc stop "${CACHE_KEY}"

    trap '' ERR HUP INT TERM
}

readonly CNAME="${INSTANCE_PREFIX}-$(uuidgen)"
[ -e "${BUILD_DIR}/vm_root" ] || {
    echo "creating ${BUILD_DIR}/vm_root"

    readonly ROOTFS_FILE="${BUILD_DIR}/${CNAME}-rootfs"

    mkdir -p "${BUILD_DIR}"
    fix_perm "${BUILD_DIR}" yes

    trap "lxc delete --force ${CNAME}" ERR HUP INT TERM

    lxc copy "${CACHE_KEY}" "${CNAME}"
    lxc start "${CNAME}"

    for file in "ssh_host_ecdsa_key" "ssh_host_ed25519_key" "ssh_host_rsa_key" "authorized_keys"; do
        echo "pushing ${file}"
        cat "${USERDATA_DIR}/${file}" | lxc file push - "${CNAME}/root/${file}"
    done

    cat "${PREFIX}/include/vm.yaml" | lxc file push - "${CNAME}/root/distrobuilder.yaml"
    cat "${PREFIX}/include/vm-script" | lxc file push - "${CNAME}/root/build.sh" --mode=755

    lxc exec "${CNAME}" -- /root/build.sh

    fallocate --length 512M "${ROOTFS_FILE}"
    fix_perm "${ROOTFS_FILE}"

    mkfs.ext2 -L "root" "${ROOTFS_FILE}"

    mnt="${ROOTFS_FILE}.mnt"
    mkdir "${mnt}"
    mount "${ROOTFS_FILE}" "${mnt}"

    lxc exec "${CNAME}" -- tar -cf - -C /root/build/rootfs/ . \
        | tar -xf - -C "${mnt}"

    lxc delete --force "${CNAME}"
    umount "${mnt}" && rmdir "${mnt}"

    trap '' ERR HUP INT TERM

    mv "${ROOTFS_FILE}" "${BUILD_DIR}/vm_root"
}

[ -e "${BUILD_DIR}/vm_kernel" ] || {
    echo "creating ${BUILD_DIR}/vm_kernel"

    cp /run/imageloader/termina-dlc/package/root/vm_kernel "${BUILD_DIR}/vm_kernel"
    fix_perm "${BUILD_DIR}/vm_kernel"
}

[ -e "${BUILD_DIR}/vm_state" ] || {
    echo "creating ${BUILD_DIR}/vm_state"

    readonly STATE_FILE="${BUILD_DIR}/${CNAME}-state"
    fallocate --length 10G "${STATE_FILE}"
    fix_perm "${STATE_FILE}"

    mkfs.ext4 -L "stateful" "${STATE_FILE}"

    mnt="${STATE_FILE}.mnt"
    mkdir -p "${mnt}"

    mount "${STATE_FILE}" "${mnt}"

    mkdir -p "${mnt}/home/.ssh"
   	chown -R 1000:1000 "${mnt}/home"
   	chmod -R 700 "${mnt}/home" 

    umount "${mnt}" && rmdir "${mnt}"

    mv "${STATE_FILE}" "${BUILD_DIR}/vm_state"
}

[ -e "${BUILD_DIR}/run.sh" ] || {
    echo "creating ${BUILD_DIR}/run.sh"
    
    cp "${PREFIX}/include/run.sh" "${BUILD_DIR}/run.sh"
    fix_perm "${BUILD_DIR}/run.sh" yes
}

echo done
