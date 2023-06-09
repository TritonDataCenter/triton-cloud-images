#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2023 MNX Cloud, Inc.
#

export PATH := $(PATH):$(PWD)/deps/py-venv/bin

STAMP       = $(shell date +%Y%m%d)

ALMA_V	    = almalinux-8 almalinux-9
DEBIAN_V    = debian-11
ROCKY_V	    = rocky-8 rocky-9
UBUNTU_V    = ubuntu-2004 ubuntu-2204

ifeq ($(shell uname -s),SunOS)
	PACKER_EXTRA_ARGS =
	OUTPUT_TYPE       = zfs
else ifeq ($(shell uname -s),Linux)
	PACKER_EXTRA_ARGS =
	OUTPUT_TYPE       = raw
endif
SUFFIX      = smartos-$(STAMP).x86_64.$(OUTPUT_TYPE)

DISTROS     = deps almalinux debian rocky ubuntu

.INTERMEDIATE: $(DISTROS)
.PRECIOUS: output/%-$(SUFFIX).gz
.PHONY: all

all: deps $(DISTROS)

include Makefile.deps

almalinux: $(ALMA_V)
debian: $(DEBIAN_V)
rocky: $(ROCKY_V)
ubuntu: $(UBUNTU_V)

# output/%-$(SUFFIX): %-smartos.pkr.hcl
# 	@echo "create $@"
# 	@mkdir output 2>/dev/null || true
# 	@touch $@
#
# output/%-$(SUFFIX).gz: output/%-$(SUFFIX)
# 	@echo "create $@"
# 	@gzip $<

# %: deps %-smartos.pkr.hcl # output/%-$(SUFFIX).gz
# 	./build_all.sh $@

check:
	packer validate .

clean:
	rm -rf output
