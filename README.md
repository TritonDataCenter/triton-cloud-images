<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.

    Copyright 2023 MNX Cloud, Inc.
 -->

# Triton DataCenter and SmartOS Cloud Images

The Triton DataCenter and SmartOS cloud images repo was based on [AlmaLinux cloud-images](https://github.com/AlmaLinux/cloud-images) repo.

This project uses [Packer](https://www.packer.io/) templates and and Ansible for building the images.

## Build details

* Images are produce using `packer` and the distro's native installer automation mechanism.
* `ansible` is used to prepare the image contents.
* Swap is disabled in all kickstarts, and preseed configurations.
* cloud-init is used for provision-time guest configuration.
* `triton-guest` systemd service will set hostid and root password from generated metadata.

## Available Images

| Name        | Version |
| :---------: | :-----: |
| AlmaLinux   | 8       |
| AlmaLinux   | 9       |
| Debian      | 11      |
| Debian      | 12      |
| Rocky Linux | 8       |
| Rocky Linux | 9       |
| Ubuntu      | 20.04   |
| Ubuntu      | 22.04   |

## Requirements

Only building on SmartOS with bhyve is supported. When building on SmartOS, the build script will ensure any necessary dependencies are correctly installed. Building with Linux using the [qemu plugin](https://github.com/hashicorp/packer-plugin-qemu) is theoretically possible, but the build script cannot be used. Also due to divergences in ZFS on Linux and illumos ZFS, zfs datasets from Linux cannot be imported to SmartOS.

Images produced will be usable with KVM as well as Bhyve.

## Building with Bhyve and packer on SmartOS

We have created a [packer plugin for bhyve](https://github.com/TritonDataCenter/packer-plugin-bhyve) that works with SmartOS (and should be compatible with other illumos distributions). Please report any issues that you find.

Building images requires additional services to be installed, running, and properly configured. The build script will attempt to make the proper modifications to the build environment. Because of this, building images should be done in a zone dedicated for this purpose, and not general purpose dev environments.

### Granting permission for a zone to use Bhyve

You must use a `joyent` brand zone `base-64-lts@22.4.0` or later, with a delegated dataset. The nic will need `"allow_ip_spoofing": true`. If you are using a stand-alone SmartOS server, add this to the JSON when creating the zone. If you are using Triton, you will need to add it via NAPI (AdminUI can also be used). For example:

```sh
sdc-napi /nics/00:53:37:aa:bb:cc -X PUT -d '{"allow_ip_spoofing": true}'
```

After provisioning some additional zone setup is required to grant the zone access to the bhyve devices. This must be done on the *compute node* and is *not* something you should grant to untrusted tenants.

```sh
zonecfg -z <uuid> <<EOF
set limitpriv=default,proc_clock_highres,sys_dl_config
add device
set match="/dev/viona"
end
add device
set match="/dev/vmm*"
end
commit
exit
EOF
```

The build script will handle configuring networking, NAT, and routing.

### Build Guest Network Configuration

**Note:** This entire section is for reference only. Network configuration and services are handled by the build script but it is included here to help readers understand how networking is configured for the image creation process. This section may help diagnose any networking problems encountered during image generation.

#### Interface Configuration

isc-dhcpd listens on `dhcp0` and hosts the packer http server, and then packer0 is what bhyve uses for the VM. **Note:** isdc-dhcpd may go into maintenance when the zone boots
if the `dhcp0` interface isn't present.

```sh
dladm create-etherstub -t images0
dladm create-vnic -t -l images0 dhcp0
dladm create-vnic -t -l images0 packer0
ifconfig dhcp0 plumb up
ifconfig packer0 plumb
ifconfig dhcp0 10.0.0.1 netmask 255.255.255.0
```

#### NAT Configuration

```sh
# cat > /etc/ipf/ipnat.conf <<EOF
map net0 10.0.0.10/32 -> 0/32
EOF
# routeadm -u -e ipv4-forwarding
# svcadm enable ipfilter
# ipnat -l
```

#### dhcp server configuration

**Note:** This will be handled for you by the build script. This is for reference only.

`/opt/local/etc/dhcp/dhcpd.conf`:

```conf
authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
        option routers 10.0.0.1;
        option domain-name-servers 1.1.1.1;
        range 10.0.0.10 10.0.0.20;
}
```

### Generate Images

The available build targets can be discovered with:

```sh
./build_all.sh list
```

To generate images for all targets, run:

```sh
./build_all.sh
```

To generate images for a subset of targets, pass only targets you wish to create:

```sh
./build_all.sh <target1> <target2>
```
