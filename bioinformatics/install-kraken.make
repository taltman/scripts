## -*-Makefile-*-
## This Makefile helps orchestrate the installation of Kraken.

#### Parameters:

## This is the path to the Git repo, or the unpacked Kraken tarball:
repo_prefix            := $(HOME)/repos
jellyfish-tarball-name := jellyfish-1.1.11
jellyfish-home         := $(repo_prefix)/kraken/third-party/$(jellyfish-tarball-name)
jellyfish-url          := http://www.cbcb.umd.edu/software/jellyfish/$(jellyfish-tarball-name).tar.gz
## A directory in the user's PATH where a symlink to kraken can be placed:
user-bin-dir           := $(HOME)/local/bin

#### Installation:

$(repo_prefix)/kraken:
	echo "Let's get kraken!!!"
	cd $(repo_prefix) && git clone "git@github.com:DerrickWood/kraken.git"

install-kraken: $(repo_prefix)/kraken

$(jellyfish-home):
	mkdir -p $(repo_prefix)/kraken/third-party
	cd $(repo_prefix)/kraken/third-party \
		&& wget jellyfish-tarball-url \
		&& tar xzf $(jellyfish-tarball-name).tar.gz \
		&& ./configure --prefix=$(jellyfish_home) \
		&& make \
		&& make install \
		&& ln -s $(jellyfish_home)/bin/jellyfish $(user-bin-dir)/jellyfish

install-jellyfish: $(jellyfish_home)

.PHONY: install-kraken install-jellyfish