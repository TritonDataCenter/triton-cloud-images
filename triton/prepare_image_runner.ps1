# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2018, Joyent, Inc.
#
# This file fetches any prepare-image script sent over by imgapi, and runs it.
# The prepare-image script is only provided through mdata-get when a new image
# is being prepared from the current VM; if it is not provided, nothing happens
# and boot continues as normal.
#
# This file can/should be run every time windows boots to support
# 'vmadm create -S'. While it can be run manually, that's unsupported.

$meta_file = 'c:\smartdc\prepare-image.ps1'

c:\smartdc\bin\mdata-get.exe sdc:operator-script > $meta_file

# If we received a proper operator script, it should contain "prepare-image"
# calls in it
$real = Select-String -Path $meta_file -Pattern 'prepare-image'
if ($real) {
    Invoke-Expression $meta_file
    Stop-Computer
}

Remove-Item -Path $meta_file
