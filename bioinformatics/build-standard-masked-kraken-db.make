## Automate the building of the standard Kraken database, but masked using dustmasker.

SHELL          := /bin/bash -e
TMPDIR         ?= /tmp
dest-dir       := $(CURDIR)
kraken-db-name := kraken-standard-dusted-db

## Export vars:
export TMPDIR

## Build kraken DB
download-kraken-input-sequences:
	cd $(TMPDIR) \
		&& mkdir -p kraken-dbs \
		&& cd kraken-dbs \
		&& time kraken-build --download-library human    --db $(kraken-db-name) \
		&& time kraken-build --download-library viruses  --db $(kraken-db-name) \
		&& time kraken-build --download-library plasmids --db $(kraken-db-name) \
		&& time kraken-build --download-library bacteria --db $(kraken-db-name)

##&& time kraken-build --download-taxonomy --db $(kraken-db-name) \
dust-kraken-input-sequences: download-kraken-input-sequences

build-kraken-dusted-db: dust-kraken-input-sequences
	cd $(TMPDIR)/kraken-dbs \
		&& time kraken-build --build $(kraken-db-name) \
		&& time kraken-build --clean $(kraken-db-name)

copy-kraken-dusted-db:
	time rsync -a $(TMPDIR)/kraken-dbs/$(kraken-db-name) $(dest-dir)

