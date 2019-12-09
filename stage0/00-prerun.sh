#!/bin/bash -e

export FILES=${BASH_SOURCE##*/}.d
if [ ! -d "${ROOTFS_DIR}" ]; then
	bootstrap buster "${ROOTFS_DIR}" http://raspbian.raspberrypi.org/raspbian/
fi
