#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2023 MNX Cloud, Inc.
#

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

function stack_trace
{
    set +o xtrace

    (( cnt = ${#FUNCNAME[@]} ))
    (( i = 0 ))
    while (( i < cnt )); do
        printf '  [%3d] %s\n' "${i}" "${FUNCNAME[i]}"
        if (( i > 0 )); then
            line="${BASH_LINENO[$((i - 1))]}"
        else
            line="${LINENO}"
        fi
        printf '        (file "%s" line %d)\n' "${BASH_SOURCE[i]}" "${line}"
        (( i++ ))
    done
}

function fatal
{
    # Disable error traps from here on:
    set +o xtrace
    set +o errexit
    set +o errtrace
    trap '' ERR

    echo "$(basename "$0"): fatal error: $*" >&2
    stack_trace
    exit 1
}

function trap_err
{
    st=$?
    fatal "exit status ${st} at line ${BASH_LINENO[0]}"
}

set -o pipefail
set -o errexit

# shellcheck disable=SC2164
TOP=$(cd "$(dirname "$0")/"; pwd)

export PATH="${TOP}/deps:${TOP}/deps/py-venv/bin:$PATH"

# We currently only support generating images on illumos and Linux.
# Here we really need to make sure we're using *illumos* and not Solaris so
# we need to first check `uname -o`. But not all systems support `-o` (e.g.,
# NetBSD) so we'll fall back to `-s` so that there's *some* value in SYSTYPE
# before we do the system check.
SYSTYPE=$(uname -o || uname -s)
case $SYSTYPE in
    illumos)
        if ! [[ -c /dev/viona ]] || ! [[ -c /dev/vmmctl ]] || \
           ! [[ -d /dev/vmm ]]; then
            printf 'WARNING: Bhyve not available. See the README.md for zone\n'
            printf 'requirements.\n'
            export BHYVE=false
        else
            vmm=bhyve
        fi
        if [[ -z $vmm ]]; then
            if ! [[ -c /dev/kvm ]]; then
                printf 'WARNING: KVM not available. See the README.md for zone\n'
                printf 'requirements.\n'
                export QEMU=false
            else
                vmm=qemu
            fi
        fi
        if [[ -z $vmm ]]; then
            printf 'Cannot create vms'
            exit 1
        fi
        ;;
    *Linux) # Can be GNU/Linux or just Linux
        printf 'WARNING: Linux can be used for development, but will only\n'
        printf 'create RAW images. In order to use the image you will need to\n'
        # shellcheck disable=SC2016
        printf '`dd` the raw image to a zvol on SmartOS, then `zfs send` it.\n'
        vmm=qemu
        ;;
    *)
        printf 'Building on %s is not currently supported\n' "$OSTYPE"
        exit 1
        ;;
esac

# Enable debug logging output from packer
export PACKER_LOG=1
export PACKER_PLUGIN_PATH=${TOP}/packer_plugins/
export PACKER_CONFIG_DIR=${TOP}/packer_config/
export PACKER_CACHE_DIR=${TOP}/packer_cache/
export CHECKPOINT_DISABLE=1

IMG_VERSION=$(date +%Y%m%d)

function generate_manifest
{
    if [[ $OSTYPE != 'solaris2.11' ]]; then
        printf 'Image %s output is not SmartOS compatible ZFS data stream.\n' "$1"
        printf 'Skipping manifest.\n'
        return
    fi
    local published_at os sha1 size desc home imagefile

    imagefile="output/${1}-smartos-${IMG_VERSION}.x86_64.zfs"

    published_at=$(date +%FT%T%Z)
    os=$(json -f imgconfigs.json "${1}.os" )
    sha1=$(digest -a sha1 "$imagefile")
    size=$(stat -c %s "${imagefile}")
    desc=$(json -f imgconfigs.json "${1}.desc" )
    home=$(json -f imgconfigs.json "${1}.homepage" )

    sed \
        -e 's/@UUID@/'"$(uuid -4)"'/g' \
        -e 's/@NAME@/'"${1}"'/g' \
        -e 's/@VERSION@/'"${IMG_VERSION}"'/g' \
        -e 's/@PUBLISHED_AT@/'"${published_at}"'/g' \
        -e 's/@OS@/'"${os}"'/g' \
        -e 's/@SHA1@/'"${sha1}"'/g' \
        -e 's/@SIZE@/'"${size}"'/g' \
        -e 's/@DESCRIPTION@/'"${desc}"'/g' \
        -e 's/@HOMEPAGE@/'"${home}"'/g' \
        manifest.in > "output/${1}-${IMG_VERSION}.json"
}

function generate_all_manifests
{
    # Get the list of images...
    mapfile -t all_images < <(json -f imgconfigs.json -Ma key)
    # ...and Bob's your uncle
    for img in "${all_images[@]}"; do
        generate_manifest "$img"
    done
}

function packer_init
{
    printf 'Initializing packer...'
    packer init .
}

function ensure_services
{
    printf 'Setting up SMF services...\n'
    if ! svcs -H image-networking; then
        mkdir -p /opt/custom/smf || true
        cp smf/smf.xml /opt/custom/smf/image-networking.xml
        cp smf/method.sh /opt/custom/smf/imgnet.sh
        chmod +x /opt/custom/smf/imgnet.sh
        svccfg import /opt/custom/smf/image-networking.xml
    fi
    # This may be overly fragile. If we're going to change the contents of the
    # file then we'll need to recalculate the checksum.
    if ! digest -a sha1 /etc/ipf/ipnat.conf | grep dfe9e37e04cc20ff27518c05e7a25f644be15e86 ; then
        printf 'map net0 10.0.0.0/24 -> 0/32\n' > /etc/ipf/ipnat.conf
        svcadm restart ipfilter
    fi
    if ! digest -a sha1 /opt/local/etc/dhcp/dhcpd.conf | grep dcc4ad69a192ddf1b82be50b315a531ddeaa41ac ; then
        cp smf/dhcpd.conf /opt/local/etc/dhcp/dhcpd.conf
        svcadm restart isc-dhcpd
    fi
    # Despite earlier restarts, services may not yet be running for the first
    # time. If services are already enabled, these will be a nop.
    svcadm enable -r image-networking
    svcadm enable -r ipfilter
    svcadm enable -r isc-dhcpd
    svcadm enable -r ipv4-forwarding
}

# Check all valid
#packer validate .

if [[ $1 == "list" ]]; then
    printf 'The followng image targets are available:\n\n'
    awk '/^source / {print $3}' ./*.hcl | tr -d '"' | sed 's/-smartos.*//' | sort -u
    exit
fi

[[ -d $PACKER_PLUGIN_PATH ]] || packer_init

ensure_services

# Build any images passed on the command line, or all.
if (( BASH_ARGC > 0 )); then
    for i in "$@"; do
        build_uuid=$(uuid -v 4)
        zfs create zones/$(zonename)/data/${build_uuid}
        packer build --only="${vmm}.${i}-smartos-x86_64" -var disk_use_zvol=true -var disk_zpool="zones/$(zonename)/data/${build_uuid}" .
        zfs destroy zones/$(zonename)/data/${build_uuid}

        generate_manifest "$i"
    done
else
    packer build .
    generate_all_manifests
fi
