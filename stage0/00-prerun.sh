#!/bin/bash -e

export FILES=$(realpath files)
if [ ! -d "${ROOTFS_DIR}" ]; then
	bootstrap buster "${ROOTFS_DIR}" http://raspbian.raspberrypi.org/raspbian/
fi
