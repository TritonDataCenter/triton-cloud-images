<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.

    Copyright 2023 MNX Cloud, Inc.
 -->

# Triton DataCenter and SmartOS Cloud Images

The Triton DataCenter and SmartOS cloud images repo was based on [AlmaLinux cloud-images](https://github.com/AlmaLinux/cloud-images) repo.

This peoject uses [Packer](https://www.packer.io/) templates and and Ansible for building the images.

## Build details

* All Linux instances are currently built with LVM on the primary disk with a single logical volume (rootlv) for the root partition.
* Swap is disabled in all kickstarts, and preseed configurations.
* cloud-init will look for /dev/vdb and mount it under /data (ext4).

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

Only building on SmartOS with bhyve is supported. When building on SmartOS, the build script will ensure any necessary dependencies are correctly installed.

Images produced should be usable with KVM as well as Bhyve.

## Building with Bhyve and packer on SmartOS

We have created a [packer plugin for bhyve](https://github.com/TritonDataCenter/packer-plugin-bhyve) that works with SmartOS. Please report any issues that you find.

Building images requires additional services to be installed, running, and properly configured. The build script will attempt to make the proper modifications to the build environment. Because of this, building images should be done in a zone dedicated for this purpose, and not general purpose dev environments.

### Granting permission for a zone to use Bhyve

You must use a `joyent` brand zone `base-64-lts@22.4.0` or later, with a delegated dataset. And the nic will need `"allow_ip_spoofing": true`. If you are using a stand-alone SmartOS server, add this to the JSON when creating the zone. If you are using Triton, you will need to add it via NAPI (AdminUI can also be used).

After provisioning some additional zone setup is required to grant the zone access to the bhyve devices. This is *not* something you should grant to untrusted tenants.

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

### Configure network interfaces

**Note:** This will be handled for you by the build script. This is for reference only.

dhcp0 runs isc-dhcpd and hosts the packer http server, and then packer0 is what bhyve uses for the VM.

```sh
dladm create-etherstub -t images0
dladm create-vnic -t -l images0 dhcp0
dladm create-vnic -t -l images0 packer0
ifconfig dhcp0 plumb up
ifconfig packer0 plumb
ifconfig dhcp0 10.0.0.1 netmask 255.255.255.0
```

### Configure NAT

**Note:** This will be handled for you by the build script. This is for reference only.

```sh
# cat > /etc/ipf/ipnat.conf <<EOF
map net0 10.0.0.10/32 -> 0/32
EOF
# routeadm -u -e ipv4-forwarding
# svcadm enable ipfilter
# ipnat -l
```

### Setup dhcp server

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

### Generating an image

## FAQ

### Failed to connect to the host via scp with OpenSSH >= 9.0/9.0p1 and EL9

OpenSSH `>= 9.0/9.0p1` and EL9 support was added in [scp_90](https://github.com/AlmaLinux/cloud-images/tree/scp_90) branch instead of the `main` for backward compatibility. Please switch to this branch with `git checkout scp_90`

The Ansible's `ansible.builtin.template` module gives error on EL9 and >= OpenSSH 9.0/9.0p1 (2022-04-08) Host OS.

Error output:

```sh
fatal: [default]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via scp: bash: line 1: /usr/lib/sftp-server: No such file or directory\nConnection closed\r\n", "unreachable": true}
```

EL9 and OpenSSH >=9.0 deprecated the SCP protocol. Use the new `-O` flag until Ansible starts to use SFTP directly.

From [OpenSSH 9.0/9.0p1 \(2022-04-08\) release note:](https://www.openssh.com/txt/release-9.0)

> In case of incompatibility, the `scp(1)` client may be instructed to use
the legacy scp/rcp using the `-O` flag.

See: [OpenSSH SCP deprecation in RHEL 9: What you need to know](https://www.redhat.com/en/blog/openssh-scp-deprecation-rhel-9-what-you-need-know)

Add `extra_arguments  = [ "--scp-extra-args", "'-O'" ]` to the Packer's Ansible Provisioner Block:

```hcl
  provisioner "ansible" {
    playbook_file    = "./ansible/gencloud.yml"
    galaxy_file      = "./ansible/requirements.yml"
    roles_path       = "./ansible/roles"
    collections_path = "./ansible/collections"
    extra_arguments  = [ "--scp-extra-args", "'-O'" ]
    ansible_env_vars = [
      "ANSIBLE_PIPELINING=True",
      "ANSIBLE_REMOTE_TEMP=/tmp",
      "ANSIBLE_SSH_ARGS='-o ControlMaster=no -o ControlPersist=180s -o ServerAliveInterval=120s -o TCPKeepAlive=yes'"
    ]
  }
```

### Packer's Ansible Plugin can't connect via SSH on SHA1 disabled system

Error output:

```sh
fatal: [default]: UNREACHABLE! => {"changed": false, "msg": "Data could not be sent to remote host \"127.0.0.1\". Make sure this host can be reached over ssh: ssh_dispatch_run_fatal: Connection to 127.0.0.1 port 43729: error in libcrypto\r\n", "unreachable": true}
```

Enable the `SHA1` on the system's default crypto policy until Packer's Ansible Plugin use a stronger key types and signature algorithms(`rsa-sha2-256`, `rsa-sha2-512`, `ecdsa-sha2-nistp256`, `ssh-ed25519`) than `ssh-rsa`.

Fedora and EL:

```sh
update-crypto-policies --set DEFAULT:SHA1
```

### How to build AlmaLinux OS cloud images on EL

**EL8**:

See:

* ["qemu-system-x86_64": executable file not found in $PATH](https://github.com/AlmaLinux/cloud-images#qemu-system-x86_64-executable-file-not-found-in-path)

**EL9**:

See:

* ["qemu-system-x86_64": executable file not found in $PATH](https://github.com/AlmaLinux/cloud-images#qemu-system-x86_64-executable-file-not-found-in-path)
* [Packer's Ansible Plugin can't connect via SSH on SHA1 disabled system](https://github.com/AlmaLinux/cloud-images#packers-ansible-plugin-cant-connect-via-ssh-on-sha1-disabled-system)
* [Failed to connect to the host via scp with OpenSSH >= 9.0/9.0p1 and EL9](https://github.com/AlmaLinux/cloud-images#failed-to-connect-to-the-host-via-scp-with-openssh--9090p1-and-el9)
