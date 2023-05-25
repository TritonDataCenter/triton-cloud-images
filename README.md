# Triton DataCenter and SmartOS Cloud Images

The Triton DataCenter and SmartOS cloud images repo was based on [AlmaLinux cloud-images](https://github.com/AlmaLinux/cloud-images) repo.

This peoject uses [Packer](https://www.packer.io/) templates and and Ansible for building the images.


## Build details

- All Linux instances are currently built with LVM on the primary disk with a single logical volume (rootlv) for the root partition. 
- Swap is disabled in all kickstarts, and preseed configurations.
- cloud-init will look for /dev/vdb and mount it under /data (ext4).


## Available Images

| Name | Version |
| :---: | :---: |
| AlmaLinux | 8 |
| AlmaLinux | 9 |
| Debian | 11 |
| Rocky Linux | 8 |
| Rocky Linux | 9 |


## Usage

Install or Update installed Packer plugins:

```sh
packer init -upgrade .
```


### Triton DataCenter / SmartOS images


#### Build All Images
```sh
packer build .
```

#### AlmaLinux OS 8 only

```sh
packer build -only=qemu.almalinux-8-smartos-x86_64 .
```

#### AlmaLinux OS 9 only

```sh
packer build -only=qemu.almalinux-9-smartos-x86_64 .
```

#### Debian 11 only

```sh
packer build -only=qemu.debian-11-smartos-x86_64 .
```

#### Rocky Linux 8 only

```sh
packer build -only=qemu.rocky-8-smartos-x86_64 .
```

#### Rocky Linux 9 only

```sh
packer build -only=qemu.rocky-9-smartos-x86_64 .
```

## Requirements

This was tested on a baremetal Ubuntu 22.04 server.  Other variations might behave differently due to Ansible os_family changes being made upstream to support Alma and Rocky.

* [Packer](https://www.packer.io/) `>= 1.7.0`
* [Ansible](https://www.ansible.com/) `>= 2.12`
* [QEMU](https://www.qemu.org/) 
* [EDK II](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) (for UEFI supported `x86_64`)


## Building with Bhyve and packer on SmartOS

A [packer plugin for SmartOS and bhyve](https://github.com/TritonDataCenter/packer-plugin-bhyve) has been developed, and is still in development. Please report any issues.  

** If building in zone with packer-plugin-bhyve ** 

Some additional zone setup is required if building withing a native zone

```
zonecfg -z <uuid>
set limitpriv=default,proc_clock_highres,sys_dl_config
add device
  set match="/dev/viona"
end
add device
  set match="/dev/vmm*"
end
commit
exit
```

** Configure network interfaces **

dhcp0 runs isc-dhcpd and hosts the packer http server, and then packer0 is what bhyve uses for the VM.

```
dladm create-etherstub -t images0
dladm create-vnic -t -l images0 dhcp0
dladm create-vnic -t -l images0 packer0
ifconfig dhcp0 plumb up
ifconfig packer0 plumb 
ifconfig dhcp0 10.0.0.1 netmask 255.255.255.0
```

** Configure NAT **
```
# cat > /etc/ipf/ipnat.conf <<EOF
map net0 10.0.0.10/32 -> 0/32
EOF
# routeadm -u -e ipv4-forwarding
# svcadm enable ipfilter
# ipnat -l
```

** Setup dhcp server **

/opt/local/etc/dhcp/dhcpd.conf:

```
authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
        option routers 10.0.0.1;
        option domain-name-servers 1.1.1.1;
        range 10.0.0.10 10.0.0.20;
}
```

** Build process **

packer build -only=bhyve.almalinux-8-smartos-x86_64,bhyve.rocky-8-smartos-x86_64,bhyve.rocky-9-smartos-x86_64 -var vnc_bind_address=0.0.0.0 -var host_nic=dhcp0 -parallel-builds=1 .


## FAQ:


### Nothing happens after invoking the packer command

The [cracklib-dicts's](https://sourceforge.net/projects/cracklib/) `/usr/sbin/packer` takes precedence over Hashicorp's `/usr/bin/packer` in the `$PATH`.
Use `packer.io` instead of the `packer`. See: https://learn.hashicorp.com/tutorials/packer/get-started-install-cli#troubleshooting

```sh
ln -s /usr/bin/packer /usr/bin/packer.io
```

### "qemu-system-x86_64": executable file not found in $PATH

Output:

`Failed creating Qemu driver: exec: "qemu-system-x86_64": executable file not found in $PATH`

By default, Packer looks for QEMU binary as `qemu-system-x86_64`. If it is different in your system, You can set your qemu binary with the `qemu_binary` Packer variable.

on EL - `/usr/libexec/qemu-kvm`

```sh
packer build -var qemu_binary="/usr/libexec/qemu-kvm" -only=qemu.almalinux-8-gencloud-x86_64 .
```

or set the `qemu_binary` Packer variable in `.auto.pkrvars.hcl` file:

`qemu_on_el.auto.pkrvars.hcl`

```hcl
qemu_binary = "/usr/libexec/qemu-kvm"
```

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

See: [OpenSSH SCP deprecation in RHEL 9: What you need to know ](https://www.redhat.com/en/blog/openssh-scp-deprecation-rhel-9-what-you-need-know)

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

Enable the `SHA1` on the system's default crypto policy until Packer's Ansible Plugin use a stronger key types and signature algorithms(`rsa-sha2-256`,` rsa-sha2-512`, `ecdsa-sha2-nistp256`, `ssh-ed25519`) than `ssh-rsa`.

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

