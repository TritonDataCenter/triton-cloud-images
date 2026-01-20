# Checking for Updates

This document describes how to check for new releases of the operating systems built by this repository and how to apply updates.

## Overview

Each image is defined in a Packer HCL file (`*.pkr.hcl`) with version information in a `locals` block. Updates typically require changing only the version string - ISO URLs are templated and update automatically.

## Current Versions

| Distribution    | Current Version | Config File              |
|-----------------|-----------------|--------------------------|
| AlmaLinux 8     | 8.10            | almalinux-8.pkr.hcl      |
| AlmaLinux 9     | 9.7             | almalinux-9.pkr.hcl      |
| AlmaLinux 10    | 10.1            | almalinux-10.pkr.hcl     |
| Debian 12       | 12.13.0         | debian-12.pkr.hcl        |
| Debian 13       | 13.3.0          | debian-13.pkr.hcl        |
| Oracle Linux 8  | R8-U10          | oraclelinux-8.pkr.hcl    |
| Oracle Linux 9  | R9-U7           | oraclelinux-9.pkr.hcl    |
| Oracle Linux 10 | R10-U1          | oraclelinux-10.pkr.hcl   |
| Rocky Linux 8   | 8.10            | rocky-8.pkr.hcl          |
| Rocky Linux 9   | 9.7             | rocky-9.pkr.hcl          |
| Rocky Linux 10  | 10.1            | rocky-10.pkr.hcl         |
| Ubuntu 20.04    | 20.04.6         | ubuntu-20.04.pkr.hcl     |
| Ubuntu 22.04    | 22.04.5         | ubuntu-22.04.pkr.hcl     |
| Ubuntu 24.04    | 24.04.3         | ubuntu-24.04.pkr.hcl     |

## Checking for Updates by Distribution

### Debian

**Release page:** https://www.debian.org/CD/netinst/

**ISO mirror:** https://cdimage.debian.org/cdimage/

- Current releases: `debian-cd/current/`
- Archived releases: `archive/`

Check for new point releases (e.g., 12.13.0 -> 12.14.0). Debian typically releases point updates every few months.

### Ubuntu

**Release pages:**
- 20.04 (Focal): https://releases.ubuntu.com/focal/
- 22.04 (Jammy): https://releases.ubuntu.com/jammy/
- 24.04 (Noble): https://releases.ubuntu.com/noble/

Look for new point releases in the `ubuntu-XX.XX.Y-live-server-amd64.iso` filename. Ubuntu LTS releases get point updates approximately every 6 months.

### AlmaLinux

**Release page:** https://almalinux.org/blog/ (announcements)

**ISO mirror:** https://repo.almalinux.org/almalinux/

Check the version directories (8/, 9/) for new minor releases. AlmaLinux follows RHEL's release schedule.

### Rocky Linux

**Release page:** https://rockylinux.org/news/

**ISO mirror:** https://dl.rockylinux.org/stg/rocky/

Check version directories for new releases. Rocky Linux also follows RHEL's release schedule.

### Oracle Linux

**Release page:** https://blogs.oracle.com/linux/ (announcements)

**ISO mirror:** https://yum.oracle.com/ISOS/OracleLinux/

Oracle Linux uses update numbers (u1, u2, etc.) within each major version. Check for new update directories under OL8/ and OL9/.

## Applying Updates

### Standard Distributions (Debian, Ubuntu, AlmaLinux, Rocky)

Most distributions require updating only the version variable in the `locals` block:

```hcl
locals {
  debian_12_ver          = "12.13.0"  # Change this to new version
  debian_12_iso_url      = "https://..."  # Auto-updates via interpolation
  debian_12_iso_checksum = "file:https://..."  # Auto-fetches new checksums
}
```

### Oracle Linux

Oracle Linux requires updating both the URL path and the ISO filename since it uses a different versioning scheme:

```hcl
locals {
  ol9_iso_url      = "https://yum.oracle.com/ISOS/OracleLinux/OL9/u5/x86_64/OracleLinux-R9-U5-x86_64-boot.iso"
  ol9_iso_checksum = "file:https://yum.oracle.com/ISOS/OracleLinux/OL9/u5/x86_64/OracleLinux-R9-U5-x86_64-boot.iso.sha256sum"
}
```

Change `u5` to the new update number in both URLs.

## Verification Checklist

Before committing an update:

1. **Verify ISO availability** - Confirm the new ISO URL returns 200 OK
2. **Verify checksum file** - Confirm the SHA256SUMS or checksum file exists
3. **Test the build** - Run a build for the updated image
4. **Check boot and provisioning** - Verify the image boots and cloud-init works

## Quick Check Commands

Verify an ISO URL is accessible:

```bash
curl -sI "https://cdimage.debian.org/cdimage/archive/12.13.0/amd64/iso-cd/debian-12.13.0-amd64-netinst.iso" | head -1
```

Verify a checksum file exists:

```bash
curl -s "https://cdimage.debian.org/cdimage/archive/12.13.0/amd64/iso-cd/SHA256SUMS" | head -3
```

## End of Life Considerations

When a distribution version reaches end of life:

- **Debian**: Oldstable receives LTS support for ~5 years total
- **Ubuntu LTS**: Standard support for 5 years, ESM available beyond
- **AlmaLinux/Rocky**: Follow RHEL lifecycle (~10 years)
- **Oracle Linux**: Extended support available

Consider removing EOL images and adding new major versions as they become available.
