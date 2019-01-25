#### include.make
##
## A set of standard Makefile definitions to include (import) into both
## installation and pipeline execution Makefiles.

##  This Source Code Form is subject to the terms of the Mozilla Public
##  License, v. 2.0. If a copy of the MPL was not distributed with this
##  file, You can obtain one at http://mozilla.org/MPL/2.0/.


### Make Configs:

## Use Bash shell, and exit on error on any recipe line:
SHELL := /bin/bash
.SHELLFLAGS = -ec 

TMPDIR ?= /tmp


## This makes all recipe lines execute within a shared shell process:
## https://www.gnu.org/software/make/manual/html_node/One-Shell.html#One-Shell
.ONESHELL:

## If a recipe contains an error, delete the target:
## https://www.gnu.org/software/make/manual/html_node/Special-Targets.html#Special-Targets
.DELETE_ON_ERROR:

## This is necessary to make sure that these intermediate files aren't clobbered:
.SECONDARY:
