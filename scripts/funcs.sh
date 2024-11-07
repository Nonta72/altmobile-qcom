#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>

source ./scripts/vars.sh

# Remove EFI partition
remove_efi_part() {
	local IMAGE_PATH="$1"

	echo "Checking if the image has EFI partition..."

	# Create loop devices
	{
		read -r _ _ EFI_PARTITION_LOOP _  # first line:  read third word into part_fat32
		read -r _ _ ROOTFS_PARTITION_LOOP _   # second line: read third word into part_ntfs
	} < <(sudo kpartx -asv "${IMAGE_PATH}")

	# Check if the EFI partition (assumed to be partition 1) exists
	if [ -z "${ROOTFS_PARTITION_LOOP}" ]; then
		echo "EFI partition has already been deleted or not found."
		return 0
	fi

	# A temporary file for the rootfs image
	local TEMP_IMAGE_PATH="${IMAGE_PATH%.img}-rootfs.img"

	# Copy the root partition to this temporary file
	if [ -b "/dev/mapper/${ROOTFS_PARTITION_LOOP}" ]; then
		sudo sh -c "cat "/dev/mapper/${ROOTFS_PARTITION_LOOP}" > "${TEMP_IMAGE_PATH}""
		sudo kpartx -d "${IMAGE_PATH}"
	else
		echo "Error: could not remove efi partition. $(file "/dev/mapper/${ROOTFS_PARTITION_LOOP}")."
		ls "/dev/mapper/${ROOTFS_PARTITION_LOOP}"
		sudo kpartx -d "${IMAGE_PATH}"
		return 1
	fi

	# Replace the original image with the rootfs image
	mv "$TEMP_IMAGE_PATH" "$IMAGE_PATH"
	echo "EFI partition removed. Image saved as '$IMAGE_PATH'"
}

# Get alt image func
get_alt_image() {
	local LATEST_IMAGE=$(curl -s "$ALT_URL" | grep -oP \
	'alt-mobile-phosh-un-def-\d{8}-aarch64\.img\.xz' | sort -r | head -n 1)
	local EXTRACTED_IMAGE="${LATEST_IMAGE%.xz}"

	# Check if the extracted image already exists
	if [ -f "$CACHE_DIR/$EXTRACTED_IMAGE" ]; then
		echo "Extracted file '$EXTRACTED_IMAGE' already exists."
		echo "Remove it manually if you want to overwrite."
	else
		# Check if compressed image exists
		if [ -f "$CACHE_DIR/$LATEST_IMAGE" ]; then
			echo "File '$LATEST_IMAGE' is already downloaded"
		else
			# Download the image if it does not exist
			echo "Downloading latest image: ${ALT_URL}${LATEST_IMAGE}"
			curl -o "${CACHE_DIR}/${LATEST_IMAGE}" \
				"${ALT_URL}${LATEST_IMAGE}" || { echo "Download failed"; exit 1; }
		fi
		# Extract the image
		extract_image "$CACHE_DIR/$LATEST_IMAGE"
	fi

	# Try to remove the EFI partition
	remove_efi_part "$CACHE_DIR/$EXTRACTED_IMAGE"
}

extract_image() {
	echo "Starting extraction: '$1'"
	unxz "$1" || { echo "Extraction failed"; exit 1; }
	echo "Extraction completed: ${LATEST_IMAGE%.xz}"
}

# Make boot.img func
make_boot_img() {
	local IMAGE_PATH DTB_PATH
	IMAGE_PATH="$1/arch/arm64/boot/Image.gz"
	DTB_PATH="$1/arch/arm64/boot/dts/qcom/$SOC-${VENDOR}-${CODENAME}.dtb"

	mkbootimg \
		--kernel ${IMAGE_PATH}		\
		--dtb ${DTB_PATH}		\
		--cmdline "${CMDLINE}"		\
		--base 0x0			\
		--kernel_offset 0x8000		\
		--ramdisk_offset 0x1000000	\
		--tags_offset 0x100		\
		--pagesize 4096			\
		--header_version 2		\
		-o ${PACKAGES_DIR}/boot.img	\
		|| echo "Failed to make boot.img"
}

# Git clone func
git_clone() {
	local REPO_URL BRANCH
	REPO_URL=$(echo "${REPOS[$1]}" | cut -d' ' -f1)
	BRANCH=$(echo "${REPOS[$1]}" | cut -d' ' -f2)
	REPO_DIR="$2"

	# Check if directory exists
	if [ -d "$REPO_DIR" ]; then
		echo "Directory '$REPO_DIR' is already exists."
		echo "Remove it manually to re-clone."
	else
		git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR" \
			--depth 1 || { echo "Failed to clone $1"; exit 1; }
	fi
}
