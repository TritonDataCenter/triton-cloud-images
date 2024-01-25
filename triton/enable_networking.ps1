# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2018, Joyent, Inc.
#
# This file fetches networking metadata over COM2 using mdata-get and sets up
# networking statically. It can/should be run every time windows boots to update
# network details. While it can be run manually, it might stop networking for a
# few moments if network details have changed.


# Attempt to get metadata. Spin sleep until any data acquired.
function getmdata {
    $key = $args[0]

    while ($true) {
        $json = c:\smartdc\bin\mdata-get $key

        try {
            $object = $json | ConvertFrom-Json
        } catch { }

        if ($object -ne $null) {
            break;
        } else {
            Start-Sleep -Seconds 2
        }
    }        

    $object
}


$nics = getmdata sdc:nics
$resolvers = getmdata sdc:resolvers

# one NIC should be primary anyway, but if not set in the case of a single
# instance we still know it must be primary
if ($nics.length -eq 1) {
    $nics[0].primary = $true
}

# statically set the IP/netmask/gateway/DNS resolvers for each NIC, if needed
foreach ($nic in $nics) {
    $mac = $nic.mac.toUpper().replace(":", "-")
    $adapter = Get-NetAdapter | Where-Object { $_.MacAddress -eq $mac }
    $ipconfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex

    # skip setting the IP if already set, otherwise networking drops for a few
    # moments
    if ($ipconfig.IPv4Address.IPAddress -ne $nic.ip -or $ipconfig.IPv4DefaultGateway.NextHop -ne $nic.gateway) {
        $gateway = $nic.gateway
        if ($gateway -eq $null) {
            $gateway = "none"
        }

        & netsh interface ip set address $adapter.Name static $nic.ip $nic.netmask $gateway 1
    }

    # set DNS resolvers
    if ($nic.primary -and $resolvers.length -gt 0) {
        Set-DNSClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $resolvers
    }
}
