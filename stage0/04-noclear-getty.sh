#!/bin/bash -e
FILES=${BASH_SOURCE##*/}.d
install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 ${FILES}/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 ${FILES}/fstab "${ROOTFS_DIR}/etc/fstab"
