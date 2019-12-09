#!/bin/bash -e

export FILES=${BASH_SOURCE##*/}.d
install -m 644 ${FILES}/cmdline.txt "${ROOTFS_DIR}/boot/"
install -m 644 ${FILES}/config.txt "${ROOTFS_DIR}/boot/"
