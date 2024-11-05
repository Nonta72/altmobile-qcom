#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>
# Copyright (c) 2024, Victor Paul <vipollmail@gmail.com>

source ./deviceinfo

# Extract values ​​for variables:
# DEVICE_NAME / SOC / VENDOR / CODENAME
IFS=':' read -r DEVICE_NAME DEVICE <<< "${DEVICE}"
IFS='-' read -r SOC VENDOR CODENAME <<< "${DEVICE}"

# Directories
WORK_DIR=$(readlink -f "$(dirname $0)/..")
CACHE_DIR="${WORK_DIR}/cache"
BUILD_DIR="${WORK_DIR}/build"
PACKAGES_DIR="${BUILD_DIR}/packages"

# Output directories
KERNEL_PACKAGE_DIR="${BUILD_DIR}/linux-${VENDOR}-${CODENAME}"
FIRMWARE_PACKAGE_DIR="${BUILD_DIR}/firmware-${VENDOR}-${CODENAME}"
BOOT_DIR="${KERNEL_PACKAGE_DIR}/boot"

ALT_URL="https://beta.altlinux.org/mobile/sisyphus/latest/"
