STAMP       = $(shell date +%Y%m%d)

ALMA_V	    = almalinux-8 almalinux-9
DEBIAN_V    = debian-11
ROCKY_V	    = rocky-8 rocky-9
UBUNTU_V    = ubuntu-20.04 ubuntu-22.04

ifeq ($(shell uname -s),SunOS)
        PACKER_EXTRA_ARGS = 
	OUTPUT_TYPE       = zfs
else ($(shell uname -s),Linux)
        PACKER_EXTRA_ARGS = 
	OUTPUT_TYPE       = raw
endif
SUFFIX      = smartos-$(STAMP).x86_64.$(OUTPUT_TYPE).gz

.PHONY: all $(DISTROS) %
.PRECIOUS: output/%-$(SUFFIX)

include Makefile.deps

all: deps almalinux debian rocky ubuntu

almalinux: $(ALMA_V)
debian: $(DEBIAN_V)
rocky: $(ROCKY_V)
ubuntu: $(UBUNTU_V)

output/%-$(SUFFIX): %-smartos.pkr.hcl
	@mkdir output 2>/dev/null || true
	@touch $@

%: output/%-$(SUFFIX)
	@echo "create $<"

clean:
	rm -rf output
