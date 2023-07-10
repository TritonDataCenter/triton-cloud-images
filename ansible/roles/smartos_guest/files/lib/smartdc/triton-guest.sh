#!/usr/bin/env bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc. All rights reserved.
# Copyright 2023 MNX Cloud, Inc.
#
# Triton specific scripts that are ran on each boot
# this is called from systemd.

# load common functions and vars
# shellcheck disable=SC1091
. /lib/smartdc/lib_smartdc_scripts.cfg

# DO NOT use lib_smartdc_fatal in here
# You want the rest of the init script to run
# instead use info with ERROR
# this will show up in logs and on console

# Start of Main
case $(uname -s | tr '[:upper:]' '[:lower:]') in
  linux)
    :
    ;;
  *)
    lib_smartdc_info "ERROR: OS specific features not implemented"
    ;;
esac

# scripts that can run on all systems
(/lib/smartdc/set-root-authorized-keys)
if [[ ! -f /lib/smartdc/.firstboot-complete-do-not-delete ]] ; then
  (/lib/smartdc/firstboot)
fi
(/lib/smartdc/run-operator-script)

###################################
# This is now handled by cloud-init
# (/lib/smartdc/get-user-data)
# (/lib/smartdc/run-user-script)

exit 0
