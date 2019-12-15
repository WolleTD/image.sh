#!/bin/bash -e
FILENAME="etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -d "${ROOTFS_DIR}/${FILENAME%/*}"
install -m 644 files/${FILENAME} "${ROOTFS_DIR}/${FILENAME}"
