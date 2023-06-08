#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2023 MNX Cloud, Inc.
#

set -o pipefail
set -o errexit

# shellcheck disable=SC2164
TOP=$(cd "$(dirname "$0")/../"; pwd)

# We currently only support generating images on illumos and Linux.
# Here we really need to make sure we're using *illumos* and not Solaris so
# we need to first check `uname -o`. But not all systems support `-o` (e.g.,
# NetBSD) so we'll fall back to `-s` so that there's *some* value in SYSTYPE
# before we do the system check.
SYSTYPE=$(uname -o || uname -s)
case $SYSTYPE in
    illumos)
        if ! [[ -f /dev/viona ]] || ! [[ -f /dev/vmmctl ]] || \
           ! [[ -d /dev/vmm ]]; then
            printf 'WARNING: Bhyve not available. See the README.md for zone\n'
            printf 'requirements.\n'
            export BHYVE=false
        else
            vmm=bhyve
        fi
        if [[ -z $vmm ]] && ! [[ -f /dev/kvm ]]; then
            printf 'WARNING: KVM not available. See the README.md for zone\n'
            printf 'requirements.\n'
            export QEMU=false
        else
            vmm=qemu
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
export CHECKPOINT_DISABLE=1

IMG_VERSION=$(date +%Y%m%d)

generate_manifest () {
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

generate_all_manifests () {
    # Get the list of images...
    mapfile -t all_images < <(json -f imgconfigs.json -Ma key)
    # ...and Bob's your uncle
    for img in "${all_images[@]}"; do
        generate_manifest "$img"
    done
}

packer_init () {
    case $SYSTYPE in
        illumos)
            ln -s versions.pkr.hcl.smartos versions.pkr.hcl
            ;;
        *Linux)
            ln -s versions.pkr.hcl.linux versions.pkr.hcl
            ;;
        *)
            printf 'Somehow we got to packer init on an unsupported system.\n'
            exit 99
            ;;
    esac
    packer init .
}

# Check all valid
#packer validate .

[[ -d $PACKER_PLUGIN_PATH ]] || packer_init

# Build any images passed on the command line, or all.
if (( BASH_ARGC > 0 )); then
    for i in "$@"; do
        echo packer build --only="${vmm}.${i}-smartos-x86_64" .
        generate_manifest "$i"
    done
else
    echo packer build .
    generate_all_manifests
fi

