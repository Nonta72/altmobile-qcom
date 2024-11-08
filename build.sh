#!/bin/bash
# Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>

bash ./scripts/kernel_build.sh
bash ./scripts/firmware_build.sh
bash ./scripts/rootfs_build.sh
