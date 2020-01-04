#!/bin/bash -e

IMG_FILE="${WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
NOOBS_DIR="${WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}"
umount-pi-img "${IMG_FILE}"

mkdir -p "${WORK_DIR}"
cp "${BASE_WORK_DIR}/export-image/${IMG_FILENAME}${IMG_SUFFIX}.img" "${WORK_DIR}/"

rm -rf "${NOOBS_DIR}"

PARTED_OUT=$(parted -sm "${IMG_FILE}" unit b print)
BOOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 2 | tr -d B)
BOOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^1:' | cut -d':' -f 4 | tr -d B)

ROOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 2 | tr -d B)
ROOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^2:' | cut -d':' -f 4 | tr -d B)

BOOT_DEV=$(losetup --show -f -o "${BOOT_OFFSET}" --sizelimit "${BOOT_LENGTH}" "${IMG_FILE}")
ROOT_DEV=$(losetup --show -f -o "${ROOT_OFFSET}" --sizelimit "${ROOT_LENGTH}" "${IMG_FILE}")
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

umount-pi-img "${IMG_FILE}"
