#!/bin/sh
set -e

# Disable root logins
sed -i '' -e 's/^PermitRootLogin yes/#PermitRootLogin no/' /etc/ssh/sshd_config

# Purge files we no longer need
rm -rf /boot/kernel.old || true
rm -f /boot/efi/EFI/FreeBSD/*-old.efi || true
rm -f /boot/efi/EFI/BOOT/*-old.efi || true
rm -f /etc/hostid || true
rm -f /etc/machine-id || true
rm -f /etc/ssh/ssh_host_* || true
rm -f /root/*.iso || true
rm -f /root/.vbox_version || true
rm -rf /tmp/* || true
rm -rf /var/db/freebsd-update/files/* || true
rm -f /var/db/freebsd-update/*-rollback || true
rm -rf /var/db/freebsd-update/install.* || true
rm -f /var/db/pkg/repo-*.sqlite || true
rm -rf /var/log/* || true
