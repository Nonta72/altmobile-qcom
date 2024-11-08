#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>
# Copyright (c) 2024, Victor Paul <vipollmail@gmail.com>

source ./scripts/vars.sh
source ./scripts/funcs.sh

set -e

PKG_NAME=firmware-$VENDOR-$CODENAME
PKG_VERSION=1.0
FIRMWARE_DIR=${CACHE_DIR}/${PKG_NAME}

# Clone the firmware repository
mkdir -p ${CACHE_DIR}
git_clone FIRMWARE "${CACHE_DIR}/${PKG_NAME}"

# Clean the build directory
rm -rf "${FIRMWARE_PKG_DIR}"
mkdir -p "${FIRMWARE_PKG_DIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

echo \
"Name: ${PKG_NAME}
Version: ${PKG_VERSION}
Release: alt1
Summary: Firmware for ${DEVICE_NAME}
License: Distributable
Source: %{name}-%{version}.tar.gz
BuildArch: noarch

%description
%summary

%install
mkdir -p %{buildroot}/lib/firmware
tar xf %SOURCE0 -C %buildroot

%files
/lib/*
/usr/*

%changelog
* $(LANG= date +"%a %b %d %Y") ${MAINTAINER} - 1.0-alt1
- Initial package
" > "${FIRMWARE_PKG_DIR}"/SPECS/${PKG_NAME}.spec

# Check if the files exist and copy them
if [ -d "${FIRMWARE_DIR}/lib" ]; then
	cp -r ${FIRMWARE_DIR}/* "${FIRMWARE_PKG_DIR}"/SOURCES/
else
	echo "Firmware not found."
	exit 1
fi

cd "${FIRMWARE_PKG_DIR}/SOURCES"
tar -czf "${PKG_NAME}-${PKG_VERSION}.tar.gz" *
cd "${FIRMWARE_PKG_DIR}"

rpmbuild --target $ARCH --define "_topdir "${FIRMWARE_PKG_DIR}"" -bb "${FIRMWARE_PKG_DIR}"/SPECS/${PKG_NAME}.spec
rm -f ${PACKAGES_DIR}/firmware-*.noarch.rpm
cp "${FIRMWARE_PKG_DIR}"/RPMS/*/*.rpm "${PACKAGES_DIR}"

