#!/bin/bash

# Enable debug logging output from packer
#PACKER_LOG=1

# To run a single build run:
#packer build -only=qemu.almalinux-9-smartos-x86_64 .

# Check all valid
#packer validate .

# To build all .hcl files in this directory run:
packer build .

