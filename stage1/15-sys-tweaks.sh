#!/bin/bash -e
FILES=${BASH_SOURCE##*/}.d
install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 ${FILES}/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 ${FILES}/fstab "${ROOTFS_DIR}/etc/fstab"

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi
echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
echo "root:root" | chpasswd
EOF


