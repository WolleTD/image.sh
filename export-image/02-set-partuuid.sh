#!/bin/bash -e
${BASE_DIR}/scripts/genfstab -t PARTUUID "${ROOTFS_DIR}" | tee "${ROOTFS_DIR}/etc/fstab"
PARTUUID=$(lsblk -rno PARTUUID $(findmnt -no SOURCE "${ROOTFS_DIR}"))

sed -i "s/ROOTDEV/PARTUUID=${PARTUUID}/" "${ROOTFS_DIR}/boot/cmdline.txt"
