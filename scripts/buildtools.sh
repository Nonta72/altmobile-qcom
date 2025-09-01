#!/bin/bash

set -euo pipefail

log() {
    echo "[*] $1"
}

# Install the necessary tools first
sudo apt update && sudo apt install unzip build-essential gcc-aarch64-linux-gnu bc flex bison 7zip kmod bash cpio binutils tar git wget dpkg libssl-dev rpm

# On Ubuntu 24.04, the mkbootimg package is broken with the infamous error "no module named gki"
# We need to use the LineageOS prebuilt version

# Remove the package if it exists (ignore error if it doesn't)
log "Removing mkbootimg package (if installed)..."
sudo apt purge -y mkbootimg || echo "Package mkbootimg not found, skipping."

# Clone the LineageOS mkbootimg into $HOME if not already present
if [ ! -d "$HOME/mkbootimg" ]; then
    log "Cloning mkbootimg repository into \$HOME..."
    git clone https://github.com/LineageOS/android_system_tools_mkbootimg.git "$HOME/mkbootimg"
else
    log "Directory \$HOME/mkbootimg already exists, skipping..."
fi

# Symlink the scripts to /usr/bin if they don't already exist
declare -A symlinks=(
    ["$HOME/mkbootimg/mkbootimg/mkbootimg.py"]="/usr/bin/mkbootimg"
    ["$HOME/mkbootimg/repack_bootimg.py"]="/usr/bin/repack_bootimg"
    ["$HOME/mkbootimg/unpack_bootimg.py"]="/usr/bin/unpack_bootimg"
)

for src in "${!symlinks[@]}"; do
    dest="${symlinks[$src]}"
    if [ ! -e "$dest" ]; then
        log "Creating symlink: $dest -> $src"
        sudo ln -s "$src" "$dest"
    else
        log "Symlink or file $dest already exists, skipping."
    fi
done
