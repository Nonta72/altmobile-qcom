#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>
# Copyright (c) 2024, Victor Paul <vipollmail@gmail.com>

# Load device information
if [ -f "./deviceinfo" ]; then
	source "./deviceinfo"
else
	echo "Error: 'deviceinfo' file not found."
	exit 1
fi

# Ensure DEVICE variable is set
if [ -z "${DEVICE:-}" ]; then
	echo "Error: DEVICE variable is not set in 'deviceinfo'."
	exit 1
fi

# Extract values for variables: DEVICE_NAME, SOC, VENDOR, CODENAME
IFS=':' read -r DEVICE_NAME DEVICE <<< "${DEVICE}"
IFS='-' read -r SOC VENDOR CODENAME <<< "${DEVICE}"

# Directories
WORK_DIR=$(readlink -f "$(dirname $0)/..")
CACHE_DIR="${WORK_DIR}/cache"
BUILD_DIR="${WORK_DIR}/build"
PACKAGES_DIR="${BUILD_DIR}/packages"

# Output directories
KERNEL_PKG_DIR="${BUILD_DIR}/linux-${VENDOR}-${CODENAME}"
FIRMWARE_PKG_DIR="${BUILD_DIR}/firmware-${VENDOR}-${CODENAME}"
BOOT_DIR="${KERNEL_PKG_DIR}/boot"

ALT_URL="https://beta.altlinux.org/mobile/sisyphus/latest/"
