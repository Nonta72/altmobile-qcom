#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>
# Copyright (c) 2024, Victor Paul <vipollmail@gmail.com>

source ./scripts/vars.sh
source ./scripts/funcs.sh

FOLDER_NAME=linux-$VENDOR-$CODENAME-git
KERNEL_OUTPUT="${BUILD_DIR}/${FOLDER_NAME}-output"
MAKEPROPS="-j$(nproc) O=${KERNEL_OUTPUT} \
			ARCH=${ARCH} CROSS_COMPILE=aarch64-linux-gnu-"

# Clone the kernel source repository
mkdir -p "${CACHE_DIR}"
git_clone KERNEL "${CACHE_DIR}/${FOLDER_NAME}"

# Build the kernel using the specified defconfig
cd "$REPO_DIR"
make $MAKEPROPS $DEFCONFIG
make $MAKEPROPS

# Make boot.img
make_boot_img ${KERNEL_OUTPUT}

# Build and copy the rpm packages
rm -rf ${KERNEL_OUTPUT}/rpmbuild/RPMS/
make $MAKEPROPS rpm-pkg
mkdir -p "${PACKAGES_DIR}"
rm -f ${PACKAGES_DIR}/kernel-*.aarch64.rpm
cp ${KERNEL_OUTPUT}/rpmbuild/RPMS/*/*.rpm "${PACKAGES_DIR}"

