#!/bin/bash -e

FILENAME="boot/cmdline.txt"
install -m 644 files/${FILENAME} "${ROOTFS_DIR}/${FILENAME}"
FILENAME="boot/config.txt"
install -m 644 files/${FILENAME} "${ROOTFS_DIR}/${FILENAME}"
