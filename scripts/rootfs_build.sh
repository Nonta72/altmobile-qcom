#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname $0)")"
source "${SCRIPTS_DIR}/vars.sh"
source "${SCRIPTS_DIR}/funcs.sh"

echo
echo "Building the rootfs image..."

# Download, unpack and remove the EFI partition
get_alt_image

# Prepare root directory
ROOTDIR="${CACHE_DIR}/rootdir"
mkdir -p "${ROOTDIR}"

# Mount the image
sudo umount "${ROOTDIR}" > /dev/null || true
sudo mount "${CACHE_DIR}/${EXTRACTED_IMAGE}" "${ROOTDIR}" \
			|| echo "Failed to mount ${EXTRACTED_IMAGE} image"

# Modify fstab
# TODO: Just replace fstab?
sudo sed -i -e '/\/boot\/efi/d' \
	-e "/^[^ \t]*[ \t]*\/[ \t]/ c\
PARTLABEL=${PARTLABEL} / ext4 errors=remount-ro,x-systemd.growfs 1 1" \
	"${CACHE_DIR}/rootdir/etc/fstab" || echo "Failed to modify fstab"

# Install packages
if ls "${PACKAGES_DIR}"/*.rpm 1> /dev/null 2>&1; then
	sudo rpm -Uvh --noscripts --replacepkgs --root "${ROOTDIR}"	\
	--ignorearch --nodeps -i "${PACKAGES_DIR}"/*.rpm ||		\
	(echo "Error installing packages" && sudo umount "${ROOTDIR}" && exit 1)
else
	echo "Error: No RPM packages found in ${PACKAGES_DIR}."
	sudo umount "${ROOTDIR}" && exit 1
fi

echo "Unmounting the rootfs..."
# Unmount the image
sudo umount "${ROOTDIR}"
echo "Rootfs build done."
