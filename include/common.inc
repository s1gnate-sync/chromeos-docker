#!/usr/bin/env bash

readonly PREFIX="$(dirname $0)"

readonly CACHE_KEY="vm-builder-cache"

readonly INSTANCE_PREFIX="vm-builder-instance"

readonly BUILD_DIR="${PREFIX}/build"

readonly USERDATA_DIR="${PREFIX}/userdata"

die() {
	while [ "${#}" -gt 0 ]; do
		echo "${1}"
		shift
	done

	exit 1
}

parse_opts() {
	local OPTIND OPTARG OPTERR len var opt optusage optstring=""
	declare -A map
	declare -g USAGE="Usage: ${0} "
	
	while [ "$#" -gt 0 ]; do
		[ "${1:1:1}" = ":" ] && len=2 || len=1
		
		opt="${1:0:1}"
		var="${1:${len}}"
		
		map["${opt}"]="${var}"
		optstring="${optstring}${1:0:${len}}"
		
		optusage="-${opt}"
		[ "${len}" = 2 ] && optusage="${optusage} ${var^^}"
		declare -n ref="${var}"
		[ -n "${ref:-}" ] && optusage="[${optusage}]" || declare -g "${var}"=""
		USAGE="${USAGE} ${optusage}"

		shift
		
		[ "${1}" = "-" ] && {
			shift
			break
		}
	done

	while getopts ":${optstring}" "opt" "${@}"; do
		var="${map["${opt}"]:-}"
		[ -n "${var}" ] && [ "${OPTARG:-}" != "?" ] && declare -g "${var}"="${OPTARG:-1}"
	done
}

assert_root() {
	[ "$(id -u)" = "0" ] || {
		echo "${0}: must be root"
		exit 1
	}
}

fix_perm() {
	local file="${1:-}"
	local exec="${2:-no}"
	chown 1000:1000 "${file}"
	if [ "${exec}" = "yes" ]; then 
		chmod 0755 "${file}"
	else
		chmod 0655 "${file}"
	fi
}

lxc() {
	vsh "lxc $*"
}

vsh() {
	local cmd="${1:-sh}"
	command vsh --cid="${CID}" -- \
		PATH=/opt/google/lxd-next/bin:/opt/google/lxd-next/usr/bin:/usr/local/bin:/usr/bin:/bin:/opt/bin \
		LXD_CONF=/mnt/stateful/lxd_conf \
		LXD_DIR=/mnt/stateful/lxd \
		sh -c "${cmd}"
}

assert_root
