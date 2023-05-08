# Rocky 9 kickstart file

url --url https://download.rockylinux.org/stg/rocky/9/BaseOS/x86_64/os/
repo --name="BaseOS" --baseurl=https://dl.rockylinux.org/pub/rocky/9.1/BaseOS/x86_64/os/ 
repo --name="AppStream" --baseurl=https://dl.rockylinux.org/pub/rocky/9.1/AppStream/x86_64/os/ 


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
%end
