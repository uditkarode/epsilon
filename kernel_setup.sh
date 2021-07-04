#!/bin/bash
#
# Copyright (c) 2021 CloudedQuartz
#

# Script to set up environment to build an android kernel
# Assumes required packages are already installed

# Config
KERNELNAME="Delta-mod"
KERNEL_DIR="$PWD"

export AK_DIR="$PWD/flasher"
export TC_DIR="$PWD/../sweet_assets/proton-clang"
# End Config

# create assets dir
[ ! -d "$PWD/../sweet_assets" ] && mkdir ../sweet_assets

# clone_tc - clones proton clang to TC_DIR
clone_tc() {
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git $TC_DIR
}

# Actually do stuff
[ ! -d "$TC_DIR" ] && clone_tc

./kernel_build.sh
