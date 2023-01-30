export PATH:=$(PWD)/wrappers:$(PWD)/deps/py-venv/bin/:$(PATH)

PACKER_LOG=1
PACKAGES = rust py310-virtualenv py310-pip unzip

PACKER_VER=1.8.5
PACKER_URL= https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_solaris_amd64.zip

.PHONY: py-ansible-deps

deps: packages py-venv ansible-deps packer

packer: deps/packer

deps/packer: packages
	[[ -f deps/packer ]] || { cd deps ;\
	curl -LO ${PACKER_URL} ;\
	ls ;\
	unzip packer_${PACKER_VER}_solaris_amd64.zip ;\
	}

packages:
	pkgin -y in $(PACKAGES)

py-venv: deps/py-venv
deps/py-venv: packages
	! [[ -d deps/py-venv ]] && virtualenv-3.10 deps/py-venv
	source deps/py-venv/bin/activate ; pip install -r requirements.txt
	@touch $@
	: ; command -V ansible
	: ; command -V ansible-galaxy

ansible-deps: ansible-roles ansible/collections

ansible-roles: ansible/roles/ezamriy.vbox_guest
ansible/roles/ezamriy.vbox_guest:
	: ; ansible-galaxy install -r ansible/requirements.yml -p ansible/roles

ansible/collections:
	: ; ansible-galaxy collection install -r ansible/requirements.yml -p ansible/collections

all:
	./deps/packer build -only=qemu.almalinux-8-smartos-x86_64 .
