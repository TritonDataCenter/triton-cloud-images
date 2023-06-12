#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2023 MNX Cloud, Inc.
#

# shellcheck disable=SC1091
source /lib/svc/share/smf_include.sh

set -o xtrace
set -o errexit
set -o pipefail

function stack_trace
{
    set +o xtrace

    (( count = ${#FUNCNAME[@]} ))
    (( i = 0 ))
    while (( i < count )); do
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
    # shellcheck disable=SC2154
    exit "$SMF_EXIT_ERR_FATAL"
}

function trap_err
{
    st=$?
    fatal "exit status ${st} at line ${BASH_LINENO[0]}"
}

# Print to STDERR, but don't throw the ERR trap.
function warn {
    e=$1
    shift
    printf 'Error %d deleting %s\n' "$e" "$*" >&2
}

function do_start {
    dladm create-etherstub -t images0
    dladm create-vnic -t -l images0 dhcp0
    dladm create-vnic -t -l images0 packer0
    ipadm create-if -t dhcp0
    ipadm create-if -t packer0
    ipadm create-addr -t -T static -a local=10.0.0.1/24 dhcp0/a
    svcadm enable -r ipv4-forwarding
}

function do_stop {
    # If things are out of alignment, we'll just try to take everything down
    # without regard for previous errors but we'll still emit a code
    set +o errexit
    dladm delete-vnic dhcp0 || warn "$?" "vnic dhcp0"
    dladm delete-vnic packer0 || warn "$?" "vnic packer0"
    dladm delete-etherstub images0 || warn "$?" "etherstub images0"
    ipadm delete-addr dhcp0/a || warn "$?" "addr dhcp0/a"
    ipadm delete-if dhcp0 || warn "$?" "if dhcp0"
    ipadm delete-if packer0 || warn "$?" "vnic packer0"
    set -o errexit
    return 0
}

trap trap_err ERR

action="$1"

case $action in
    start) do_start ;;
    stop) do_stop ;;
    restart)
        do_stop
        do_start
        ;;
    refresh)
        : nop ;;
    *) printf 'Unsupported action: %s\n' "$action";;
esac
