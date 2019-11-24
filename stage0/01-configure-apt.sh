#!/bin/bash -e

export FILES=${BASH_SOURCE##*/}.d
install -m 644 ${FILES}/sources.list "${ROOTFS_DIR}/etc/apt/"
install -m 644 ${FILES}/raspi.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"

if [ -n "$APT_PROXY" ]; then
    sed -e "s|@APT_PROXY@|${APT_PROXY}|" ${FILES}/51cache.in > \
        "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache" 
else
	rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
fi

on_chroot apt-key add - < ${FILES}/raspberrypi.gpg.key
on_chroot << EOF
apt-get update
apt-get dist-upgrade -y
EOF
