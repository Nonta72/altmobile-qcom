#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>

source ./scripts/vars.sh
source ./scripts/funcs.sh

# Download, unpack and remove the EFI partition
get_alt_image

rm -rf ${CACHE_DIR}/rootdir && mkdir ${CACHE_DIR}/rootdir

# Mount the image
sudo mount -o loop "${CACHE_DIR}/${EXTRACTED_IMAGE}" "${CACHE_DIR}/rootdir" \
			|| echo "Failed to mount ${EXTRACTED_IMAGE} image"

# FSTAB
sudo sed -i -e '/\/boot\/efi/d' \
	-e "/^[^ \t]*[ \t]*\/[ \t]/ c\
PARTLABEL=${PARTLABEL} / ext4 errors=remount-ro,x-systemd.growfs 1 1" \
	"${CACHE_DIR}/rootdir/etc/fstab" || echo "Failed to edit fstab"

# Install packages
sudo rpm --root "${CACHE_DIR}/rootdir" --ignorearch --nodeps -i	\
		"${PACKAGES_DIR}/*.rpm"		\
		|| echo "Failed to install rpm packages"

# Unmount the image
sudo umount -l ${CACHE_DIR}/rootdir \
			|| echo "Failed to umount ${EXTRACTED_IMAGE} image"
