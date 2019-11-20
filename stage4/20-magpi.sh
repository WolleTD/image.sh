#!/bin/sh -e

FILES=${BASH_SOURCE##*/}.d
magpi_regex="MagPi[[:digit:]]*.pdf"
magpi_loc="https://www.raspberrypi.org/magpi-issues"
magpi_latest="$(curl "$magpi_loc/?C=M;O=D" -s | grep "$magpi_regex" -m 1 -o | head -n 1)"

if [ ! -f "${FILES}/$magpi_latest" ]; then
	find ${FILES}/ -regextype grep -regex "${FILES}/$magpi_regex" -delete
	wget "$magpi_loc/$magpi_latest" -O "${FILES}/$magpi_latest"
fi

file "${FILES}/$magpi_latest" | grep -q "PDF document"

install -v -o 1000 -g 1000 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/MagPi"
install -v -o 1000 -g 1000 -m 644 "${FILES}/$magpi_latest" "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/MagPi/"
