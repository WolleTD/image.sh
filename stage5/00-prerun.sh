#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	import_stage stage4
fi
