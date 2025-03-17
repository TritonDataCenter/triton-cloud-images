# OracleLinux 8 kickstart file for Generic Cloud (OpenStack) image

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2023 MNX Cloud, Inc.
#

url --url https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/
repo --name=BaseOS --baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/
repo --name=AppStream --baseurl=https://yum.oracle.com/repo/OracleLinux/OL8/appstream/x86_64/

text
skipx
eula --agreed
firstboot --disabled

lang en_US.UTF-8
keyboard us
timezone UTC --isUtc

network --bootproto=dhcp
firewall --enabled --service=ssh
services --disabled="kdump" --enabled="chronyd,rsyslog,sshd"
selinux --enforcing

# TODO: remove "console=tty0" from here
bootloader --append="console=ttyS0,115200n8 console=tty0 crashkernel=auto net.ifnames=0 tsc=reliable no_timer_check" --location=mbr --timeout=1

# Partition stuff
%pre --erroronfail

parted -s -a optimal /dev/vda -- mklabel gpt
parted -s -a optimal /dev/vda -- mkpart biosboot 1MiB 2MiB set 1 bios_grub on
parted -s -a optimal /dev/vda -- mkpart '"EFI System Partition"' fat32 2MiB 258MiB set 2 esp on
parted -s -a optimal /dev/vda -- mkpart boot xfs 258MiB 1058MiB
parted -s -a optimal /dev/vda -- mkpart primary 1058MiB 100%

%end


part biosboot  --fstype=biosboot --onpart=vda1
part /boot/efi --fstype=efi --onpart=vda2
part /boot     --fstype=xfs --onpart=vda3
part /         --fstype=xfs --onpart=vda4

rootpw --plaintext tritondatacenter

reboot --eject


%packages
@core
python3
-biosdevname
-open-vm-tools
-plymouth
-dnf-plugin-spacewalk
-rhn*
-iprutils
-iwl*-firmware
%end


# disable kdump service
%addon com_redhat_kdump --disable
%end

%post --erroronfail
dnf install -y grub2-efi-x64-modules grub2-pc-modules
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-install --target=i386-pc /dev/vda
%end