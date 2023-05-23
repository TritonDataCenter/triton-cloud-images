# AlmaLinux 8 kickstart file for Generic Cloud (OpenStack) image

url --url https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/kickstart/
repo --name=BaseOS --baseurl=https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=https://repo.almalinux.org/almalinux/8/AppStream/x86_64/os/

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

parted -s -a optimal /dev/sda -- mklabel gpt
parted -s -a optimal /dev/sda -- mkpart biosboot 1MiB 2MiB set 1 bios_grub on
parted -s -a optimal /dev/sda -- mkpart '"EFI System Partition"' fat32 2MiB 258MiB set 2 esp on
parted -s -a optimal /dev/sda -- mkpart boot xfs 258MiB 1058MiB
parted -s -a optimal /dev/sda -- mkpart primary 1058MiB 100%

%end


part biosboot  --fstype=biosboot --onpart=sda1
part /boot/efi --fstype=efi --onpart=sda2
part /boot     --fstype=xfs --onpart=sda3
part pv.01     --onpart=sda4
volgroup rootvg pv.01
logvol / --vgname=rootvg --size=5000 --name=rootlv --grow

rootpw --plaintext tritondatacenter

reboot --eject


%packages
@core
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
grub2-install --target=i386-pc /dev/sda
%end

