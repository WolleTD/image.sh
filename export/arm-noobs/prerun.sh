#!/bin/bash -e

IMAGE_FILENAME="${IMAGE_NAME}-$(date +%Y-%m-%d)"

IMAGE_FILE="${WORK_DIR}/${IMAGE_FILENAME}${IMAGE_SUFFIX}.img"
NOOBS_DIR="${WORK_DIR}/${IMAGE_FILENAME}${IMAGE_SUFFIX}"
umount-pi-img "${IMAGE_FILE}"

mkdir -p "${WORK_DIR}"
cp "${BASE_WORK_DIR}/export-image/${IMAGE_FILENAME}${IMAGE_SUFFIX}.img" "${WORK_DIR}/"

rm -rf "${NOOBS_DIR}"

PARTED_OUT=$(parted -sm "${IMAGE_FILE}" unit b print)
BOOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 2 | tr -d B)
BOOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 4 | tr -d B)

ROOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 2 | tr -d B)
ROOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 4 | tr -d B)

BOOT_DEV=$(losetup --show -f -o "${BOOT_OFFSET}" --sizelimit "${BOOT_LENGTH}" "${IMAGE_FILE}")
ROOT_DEV=$(losetup --show -f -o "${ROOT_OFFSET}" --sizelimit "${ROOT_LENGTH}" "${IMAGE_FILE}")
echo "/boot: offset $BOOT_OFFSET, length $BOOT_LENGTH"
echo "/:     offset $ROOT_OFFSET, length $ROOT_LENGTH"

mkdir -p "${WORK_DIR}/rootfs"
mkdir -p "${NOOBS_DIR}"

mount "$ROOT_DEV" "${WORK_DIR}/rootfs"
mount "$BOOT_DEV" "${WORK_DIR}/rootfs/boot"

ln -sv "/lib/systemd/system/apply_noobs_os_config.service" "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/apply_noobs_os_config.service"

bsdtar --numeric-owner --format gnutar -C "${WORK_DIR}/rootfs/boot" -cpf - . | xz -T0 > "${NOOBS_DIR}/boot.tar.xz"
umount "${WORK_DIR}/rootfs/boot"
bsdtar --numeric-owner --format gnutar -C "${WORK_DIR}/rootfs" --one-file-system -cpf - . | xz -T0 > "${NOOBS_DIR}/root.tar.xz"

umount-pi-img "${IMAGE_FILE}"
