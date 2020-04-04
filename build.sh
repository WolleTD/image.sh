#!/bin/bash

# Core function
build_Imagefile() {
    local NAME=$1
    echo "Begin ${NAME}"
    if [ -d "${NAME}" ]; then
        SOURCE_DIR="$(realpath "${NAME}")"
    elif [ -d "${BASE_DIR}/${NAME}" ]; then
        SOURCE_DIR="$(realpath "${BASE_DIR}/${NAME}")"
    else
        echo "Can't find ${NAME} in ${PWD}!" >&2
        exit 1
    fi
    pushd "${SOURCE_DIR}" > /dev/null
    IMAGE_DIR="${WORK_DIR}/${NAME}"
    if [ -f "${IMAGE_DIR}/Imagefile.lock" ]; then
        echo "Image ${NAME}: Directory busy (Imagefile.lock exists)" >&2
        exit 1
    fi
    mkdir -p "${IMAGE_DIR}"
    rm -rf "${IMAGE_DIR}/Imagefile.cache"
    touch "${IMAGE_DIR}/Imagefile.lock"
    LOG_FILE="${IMAGE_DIR}/Imagefile.log"
    ROOTFS_DIR="${IMAGE_DIR}/rootfs"

    if [ "${CLEAN}" = "1" ]; then
        rm -rf "${ROOTFS_DIR}"
    fi
    if [ -f Imagefile ]; then
        if bash -e ./Imagefile; then
            touch "${IMAGE_DIR}/Imagefile.cache"
        else
            echo "Image ${NAME} failed!" >&2
            rm "${IMAGE_DIR}/Imagefile.lock"
            exit 1
        fi
    else
        echo "${NAME}/Imagefile not found!" >&2
        exit 1
    fi
    rm "${IMAGE_DIR}/Imagefile.lock"
    popd > /dev/null
    echo "End ${NAME}"
}

if [ "$(id -u)" != "0" ]; then
	echo "Please run as root" 1>&2
	exit 1
fi

BASE_DIR="$(realpath "${BASH_SOURCE[0]%/*}")"
export BASE_DIR

if [ -f config ]; then
	# shellcheck disable=SC1091
	source config
fi

export PI_GEN=${PI_GEN:-pi-gen}
export PI_GEN_REPO=${PI_GEN_REPO:-https://github.com/RPi-Distro/pi-gen}


while getopts "c:" flag
do
	case "$flag" in
		c)
			EXTRA_CONFIG="$OPTARG"
			# shellcheck disable=SC1090
			source "$EXTRA_CONFIG"
			;;
		*)
			;;
	esac
done

if [ -z "${IMG_NAME}" ]; then
	echo "IMG_NAME not set" 1>&2
	exit 1
fi

if [ -n "$1" ]; then
    TARGET_STAGE=$1
elif [ -z "${TARGET_STAGE}" ]; then
    echo "TARGET_STAGE not set" 1>&2
    exit 1
fi

export USE_QEMU="${USE_QEMU:-0}"
export IMG_DATE="${IMG_DATE:-"$(date +%Y-%m-%d)"}"
export IMG_FILENAME="${IMG_FILENAME:-"${IMG_DATE}-${IMG_NAME}"}"
export ZIP_FILENAME="${ZIP_FILENAME:-"image_${IMG_DATE}-${IMG_NAME}"}"

export SCRIPT_DIR="${BASE_DIR}/scripts"
export PATH="${SCRIPT_DIR}:$PATH"
export WORK_DIR="${WORK_DIR:-"${BASE_DIR}/work/${IMG_DATE}-${IMG_NAME}"}"
export DEPLOY_DIR=${DEPLOY_DIR:-"${BASE_DIR}/deploy"}
export DEPLOY_ZIP="${DEPLOY_ZIP:-1}"
export DEPLOY_NOOBS="${DEPLOY_NOOBS:-1}"

export HOSTNAME=${HOSTNAME:-raspberrypi}

export FIRST_USER_NAME=${FIRST_USER_NAME:-pi}
export FIRST_USER_PASS=${FIRST_USER_PASS:-raspberry}
export WPA_ESSID
export WPA_PASSWORD
export WPA_COUNTRY
export ENABLE_SSH="${ENABLE_SSH:-0}"

export LOCALE_DEFAULT="${LOCALE_DEFAULT:-en_GB.UTF-8}"

export KEYBOARD_KEYMAP="${KEYBOARD_KEYMAP:-gb}"
export KEYBOARD_LAYOUT="${KEYBOARD_LAYOUT:-English (UK)}"

export TIMEZONE_DEFAULT="${TIMEZONE_DEFAULT:-Europe/London}"

export GIT_HASH=${GIT_HASH:-"$(git --git-dir="${BASE_DIR}/.git" rev-parse HEAD)"}

export CLEAN
export IMG_NAME
export APT_PROXY

export NAME
export SOURCE_DIR
export IMAGE_DIR
export ROOTFS_DIR
export IMG_SUFFIX
export NOOBS_NAME
export NOOBS_DESCRIPTION
export EXPORT_DIR
export EXPORT_ROOTFS_DIR
export LOG_FILE

export QUILT_PATCHES
export QUILT_NO_DIFF_INDEX=1
export QUILT_NO_DIFF_TIMESTAMPS=1
export QUILT_REFRESH_ARGS="-p ab"

# shellcheck source=scripts/commands
source "${SCRIPT_DIR}/commands"

# shellcheck source=scripts/dependencies_check
source "${SCRIPT_DIR}/dependencies_check"

dependencies_check "${BASE_DIR}/depends"

#check username is valid
if [[ ! "$FIRST_USER_NAME" =~ ^[a-z][-a-z0-9_]*$ ]]; then
	echo "Invalid FIRST_USER_NAME: $FIRST_USER_NAME"
	exit 1
fi

if [[ -n "${APT_PROXY}" ]] && ! curl --silent "${APT_PROXY}" >/dev/null ; then
	echo "Could not reach APT_PROXY server: ${APT_PROXY}"
	exit 1
fi

mkdir -p "${WORK_DIR}"

build_Imagefile "${TARGET_STAGE}"


if [[ -f "${SOURCE_DIR}/EXPORT_IMAGE" ]]; then
    CLEAN=1
    EXPORT_DIR=${SOURCE_DIR}
    # shellcheck source=/dev/null
    source "${EXPORT_DIR}/EXPORT_IMAGE"
    EXPORT_ROOTFS_DIR=${ROOTFS_DIR}
    build_Imagefile export-image
    if [ "${USE_QEMU}" != "1" ] && [ "${DEPLOY_NOOBS}" == "1" ]; then
        if [ -e "${EXPORT_DIR}/EXPORT_NOOBS" ]; then
            # shellcheck source=/dev/null
            source "${EXPORT_DIR}/EXPORT_NOOBS"
            build_Imagefile export-noobs
        fi
    fi
fi

