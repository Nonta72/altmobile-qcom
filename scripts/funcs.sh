#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>

source ./scripts/vars.sh

# Remove EFI partition
remove_efi_part() {
	local IMAGE_PATH="$1"

	# Check if the EFI partition (assumed to be partition 1) exists
	if ! parted -ms "$IMAGE_PATH" print | grep -q "^1:"; then
		echo "EFI partition has already been deleted or not found."
		return 0
	fi

	# Get START_BYTE and END_BYTE of partition 2 (assuming it's the Linux partition)
	local PART_INFO=$(parted -ms "$IMAGE_PATH" unit B print)
	local START_BYTE=$(echo "$PART_INFO" | awk -F: '/^2:/ {print substr($2, 1, length($2)-1)}')
	local END_BYTE=$(echo "$PART_INFO" | awk -F: '/^2:/ {print substr($3, 1, length($3)-1)}')

	# Validate extracted values
	if [ -z "$START_BYTE" ] || [ -z "$END_BYTE" ]; then
		echo "Error: Failed to get partition byte information." && exit 1
	fi

	local SIZE_BYTES=$((END_BYTE - START_BYTE))

	# Create a temporary file for the trimmed image
	local TEMP_IMAGE="${IMAGE_PATH%.img}-trimmed.img"

	# Copy the required bytes using tail and head
	tail -c +"$((START_BYTE + 1))" "$IMAGE_PATH" | head -c "$SIZE_BYTES" > "$TEMP_IMAGE"

	# Replace the original image with a trimmed one
	mv "$TEMP_IMAGE" "$IMAGE_PATH"
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

		# Try to remove the EFI partition
		remove_efi_part "$CACHE_DIR/$EXTRACTED_IMAGE"

		return 0
	fi

	# Check if compressed image exists
	if [ -f "$CACHE_DIR/$LATEST_IMAGE" ]; then
		echo "File '$LATEST_IMAGE' is already downloaded, starting extraction..."
		unxz -k "$CACHE_DIR/$LATEST_IMAGE" || { echo "Extraction failed"; exit 1; }
		echo "Extraction completed: '$EXTRACTED_IMAGE'"
	else
		# Download the image if it does not exist
		echo "Downloading latest image: ${ALT_URL}${LATEST_IMAGE}"
		curl -o "${CACHE_DIR}/${LATEST_IMAGE}" \
			"${ALT_URL}${LATEST_IMAGE}" || { echo "Download failed"; exit 1; }

		# Extract the downloaded file
		echo "Starting extraction: '$LATEST_IMAGE'"
		unxz -k "$CACHE_DIR/$LATEST_IMAGE" || { echo "Extraction failed"; exit 1; }
		echo "Extraction completed: '$EXTRACTED_IMAGE'"

		# Remove the compressed archive after successful extraction
		rm "$CACHE_DIR/$LATEST_IMAGE"
		echo "Compressed file '$LATEST_IMAGE' has been removed after extraction."

		# Try to remove the EFI partition
		remove_efi_part "$CACHE_DIR/$EXTRACTED_IMAGE"
	fi
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
