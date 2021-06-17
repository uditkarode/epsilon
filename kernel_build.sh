#! /bin/bash
# Copyright (C) 2020 KenHV
# Copyright (C) 2020 Starlight
# Copyright (C) 2021 CloudedQuartz
#

# Config
DEVICE="sweet"
DEFCONFIG="vendor/${DEVICE}_defconfig"
LOG="$HOME/log.txt"

# Export arch and subarch
ARCH="arm64"
SUBARCH="arm64"
export ARCH SUBARCH

KERNEL_DIR="$PWD"

KERNEL_IMG=$KERNEL_DIR/out/arch/$ARCH/boot/Image.gz
KERNEL_DTBO=$KERNEL_DIR/out/arch/$ARCH/boot/dtbo.img
# End config

# Function definitions

# build_setup - enter kernel directory and get info for caption.
# also removes the previous kernel image, if one exists.
build_setup() {
    cd "$KERNEL_DIR" || echo -e "\nKernel directory ($KERNEL_DIR) does not exist" || exit 1

    [[ ! -d out ]] && mkdir out
    [[ -f "$KERNEL_IMG" ]] && rm "$KERNEL_IMG"
	find out/ -name "*.dtb*" -type f -delete
}

# build_config - builds .config file for device.
build_config() {
	make O=out $1 -j$(nproc --all)
}
# build_kernel - builds defconfig and kernel image using llvm tools, while saving the output to a specified log location
# only use after runing build_setup()
build_kernel() {

    BUILD_START=$(date +"%s")
    make -j$(nproc --all) O=out \
                PATH="$TC_DIR/bin:$PATH" \
                CC="clang" \
                CROSS_COMPILE=$TC_DIR/bin/aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=$TC_DIR/bin/arm-linux-gnueabi- \
                LLVM=llvm- \
                AR=llvm-ar \
                NM=llvm-nm \
                OBJCOPY=llvm-objcopy \
                OBJDUMP=llvm-objdump \
                STRIP=llvm-strip |& tee $LOG

    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
}

# build_end - creates and sends zip
build_end() {
    if ! [ -a "$KERNEL_IMG" ]; then
        echo -e "\n> $KERNEL_IMG does not exist - Build failed."
        exit 1
    fi

    echo -e "\n> Build successful! generating flashable zip..."
    cd "$AK_DIR" || echo -e "\nAnykernel directory ($AK_DIR) does not exist" || exit 1
    rm -fv zImage
    rm -fv dtbo.img
    rm -fv zipsigner-4.0.jar
    mv "$KERNEL_IMG" "$AK_DIR"/zImage
    mv "$KERNEL_DTBO" "$AK_DIR"
    [ ! -f "avbtool.py" ] && curl https://android.googlesource.com/platform/external/avb/+/refs/heads/master/avbtool.py?format=TEXT | base64 --decode > avbtool.py
    python3 avbtool.py add_hash_footer --image dtbo.img --partition_size=33554432 --partition_name dtbo
    ZIP_NAME="delta-mod-$(date +"%H:%M:%S")"
    zip -r9 "$ZIP_NAME".zip 'anykernel.sh' 'dtbo.img' 'zImage' 'META-INF' 'tools'

    echo "$ZIP_NAME" "Time taken: $((DIFF / 60))m $((DIFF % 60))s"
}

# End function definitions

COMMIT=$(git log --pretty=format:"%s" -1)
COMMIT_SHA=$(git rev-parse --short HEAD)
KERNEL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

CAPTION=$(echo -e \
"HEAD: $COMMIT_SHA: $COMMIT
Branch: $KERNEL_BRANCH")

echo "-- Build Triggered --
$CAPTION"

# Build device 1
build_setup
build_config $DEFCONFIG
build_kernel
build_end $DEVICE
