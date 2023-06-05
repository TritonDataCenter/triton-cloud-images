export PATH := $(PATH):$(PWD)/deps/py-venv/bin

STAMP       = $(shell date +%Y%m%d)

ALMA_V	    = almalinux-8 almalinux-9
DEBIAN_V    = debian-11
ROCKY_V	    = rocky-8 rocky-9
UBUNTU_V    = ubuntu-20.04 ubuntu-22.04

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

output/%-$(SUFFIX): %-smartos.pkr.hcl
	@echo "create $@"
	@mkdir output 2>/dev/null || true
	@touch $@

output/%-$(SUFFIX).gz: output/%-$(SUFFIX)
	@echo "create $@"
	@gzip $<

%: output/%-$(SUFFIX).gz
	@ :

clean:
	rm -rf output
