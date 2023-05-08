# AlmaLinux 8 kickstart file for Generic Cloud (OpenStack) image

url --url https://download.rockylinux.org/stg/rocky/8/BaseOS/x86_64/os/
repo --name="BaseOS" --baseurl=http://dl.rockylinux.org/pub/rocky/8.7/BaseOS/x86_64/os/ 
repo --name="AppStream" --baseurl=http://dl.rockylinux.org/pub/rocky/8.7/AppStream/x86_64/os/ 

text
skipx
eula --agreed
firstboot --disabled

lang en_US.UTF-8
keyboard us
timezone UTC --isUtc

network --bootproto=dhcp --device=link --activate
network --hostname=rocky8.localdomain

firewall --enabled --service=ssh
services --disabled="kdump" --enabled="chronyd,rsyslog,sshd"
selinux --enforcing

# TODO: remove "console=tty0" from here
bootloader --append="console=ttyS0,115200n8 console=tty0 crashkernel=auto net.ifnames=0 tsc=reliable no_timer_check" --location=mbr --timeout=1
zerombr

# Partition stuff
zerombr
clearpart --all --initlabel --disklabel=gpt

part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --label=boot
part pv.01     --size=1    --ondisk=sda      --grow
volgroup rootvg pv.01
logvol / --vgname=rootvg --size=8000 --name=rootlv --grow

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


%post
%end
