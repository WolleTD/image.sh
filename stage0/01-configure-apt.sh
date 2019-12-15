#!/bin/bash -e

FILENAME="etc/apt/sources.list"
install -m 644 files/${FILENAME} "${ROOTFS_DIR}/${FILENAME}"
FILENAME="etc/apt/sources.list.d/raspi.list"
install -m 644 files/${FILENAME} "${ROOTFS_DIR}/${FILENAME}"

FILENAME="etc/apt/apt.conf.d/51.cache"
if [ -n "$APT_PROXY" ]; then
    sed -e "s|@APT_PROXY@|${APT_PROXY}|" files/${FILENAME}.in > \
        "${ROOTFS_DIR}/${FILENAME}"
else
    rm -f "${ROOTFS_DIR}/${FILENAME}"
fi

on_chroot apt-key add - < files/raspberrypi.gpg.key
on_chroot << EOF
apt-get update
apt-get dist-upgrade -y
EOF
