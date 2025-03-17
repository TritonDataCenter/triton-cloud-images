# OracleLinux 9 kickstart file for Generic Cloud (OpenStack) x86_64-v2 image

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2025 MNX Cloud, Inc.
#

url --url https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64/
repo --name=BaseOS --baseurl=https://yum.oracle.com/repo/OracleLinux/OL9/baseos/latest/x86_64/
repo --name=AppStream --baseurl=https://yum.oracle.com/repo/OracleLinux/OL9/appstream/x86_64/

text
skipx
eula --agreed
firstboot --disabled

lang C.UTF-8
keyboard us
timezone UTC --utc

network --bootproto=dhcp
firewall --enabled --service=ssh
services --disabled="kdump" --enabled="chronyd,rsyslog,sshd"
selinux --enforcing

bootloader --timeout=1 --location=mbr --append="console=ttyS0,115200n8 no_timer_check crashkernel=auto tsc=reliable net.ifnames=0"

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

reboot


%packages --inst-langs=en
@core
dracut-config-generic
usermode
-biosdevname
-dnf-plugin-spacewalk
-dracut-config-rescue
-iprutils
-iwl*-firmware
-langpacks-*
-mdadm
-open-vm-tools
-plymouth
-rhn*
%end


# disable kdump service
%addon com_redhat_kdump --disable
%end

%post --erroronfail
# permit root login via SSH with password authetication
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitrootlogin.conf
dnf install -y grub2-efi-x64-modules grub2-pc-modules
grub2-install --target=i386-pc /dev/vda
%end
