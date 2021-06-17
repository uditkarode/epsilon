#!/bin/bash
#
# Copyright (c) 2021 CloudedQuartz
#

# Script to set up environment to build an android kernel
# Assumes required packages are already installed

# Config
KERNELNAME="Delta-mod"
KERNEL_DIR="$PWD"
AK_REPO="https://github.com/TheStaticDesign/AnyKernel3"
AK_BRANCH="sweet"

export AK_DIR="$PWD/../sweet_assets/AnyKernel3"
export TC_DIR="$PWD/../sweet_assets/proton-clang"
# End Config

# create assets dir
[ ! -d "$PWD/../sweet_assets" ] && mkdir ../sweet_assets

# clone_tc - clones proton clang to TC_DIR
clone_tc() {
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git $TC_DIR
}

# Clones anykernel
clone_ak() {
	git clone $AK_REPO $AK_DIR -b $AK_BRANCH
}

# Actually do stuff
[ ! -d "$TC_DIR" ] && clone_tc
[ ! -d "$AK_DIR" ] && clone_ak

./kernel_build.sh
