#!/bin/bash

error() { echo "$1" 1>&2; exit 1; }

# Core function
build_Imagefile() {
    local NAME=$1
    echo "Begin ${NAME}"

    if [ -d "${NAME}" ]; then
        SOURCE_DIR="$(realpath "${NAME}")"
    elif [ -d "${BASE_DIR}/${NAME}" ]; then
        SOURCE_DIR="$(realpath "${BASE_DIR}/${NAME}")"
    else
        error "Can't find ${NAME} in ${PWD} or ${BASE_DIR}!"
    fi
    pushd "${SOURCE_DIR}" > /dev/null

    IMAGE_DIR="${WORK_DIR}/${NAME}"
    [ -f "${IMAGE_DIR}/Imagefile.lock" ] &&     \
        error "Image ${NAME}: Directory busy (Imagefile.lock exists)"

    mkdir -p "${IMAGE_DIR}"
    rm -rf "${IMAGE_DIR}/Imagefile.cache"
    touch "${IMAGE_DIR}/Imagefile.lock"
    LOG_FILE="${IMAGE_DIR}/Imagefile.log"
    ROOTFS_DIR="${IMAGE_DIR}/rootfs"

    [ "${CLEAN}" = "1" ] && rm -rf "${ROOTFS_DIR}"
    
    [ -f defconfig ] && source defconfig

    if [ -f Imagefile ]; then
        if bash -e ./Imagefile; then
            touch "${IMAGE_DIR}/Imagefile.cache"
        else
            rm "${IMAGE_DIR}/Imagefile.lock"
            error "Image ${NAME} failed!"
        fi
    else
        error "${NAME}/Imagefile not found!"
    fi
    rm "${IMAGE_DIR}/Imagefile.lock"
    popd > /dev/null
    echo "End ${NAME}"
}

[ "$(id -u)" == "0" ] || error "Please run as root"

BASE_DIR="$(realpath "${BASH_SOURCE[0]%/*}")"
export BASE_DIR

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

TARGET=$1
[ -n "${TARGET}" ] || error "TARGET not set"

# shellcheck disable=SC1091
[ -f config ] && source config

export GIT_HASH="$(git --git-dir="${BASE_DIR}/.git" rev-parse HEAD)"

export SCRIPT_DIR="${BASE_DIR}/scripts"
export PATH="${SCRIPT_DIR}:$PATH"
export WORK_DIR="${WORK_DIR:-"${BASE_DIR}/work"}"
export DEPLOY_DIR=${DEPLOY_DIR:-"${PWD}/deploy"}

export APT_PROXY

export NAME
export SOURCE_DIR
export IMAGE_DIR
export ROOTFS_DIR
export EXPORT_DIR
export EXPORT_ROOTFS_DIR
export LOG_FILE
export IMAGE_NAME

export QUILT_NO_DIFF_INDEX=1
export QUILT_NO_DIFF_TIMESTAMPS=1
export QUILT_REFRESH_ARGS="-p ab"

# shellcheck source=scripts/commands
source "${SCRIPT_DIR}/commands"

[[ -z "${APT_PROXY}" ]] ||                                  \
    curl --silent "${APT_PROXY}" >/dev/null ||              \
	error "Could not reach APT_PROXY server: ${APT_PROXY}"

mkdir -p "${WORK_DIR}"

build_Imagefile "${TARGET}"

if [[ -n "${EXPORT_TYPE}" && "${IMAGESH_SUB}" != "1" ]]; then

    if [ -z "${IMAGE_NAME}" ]; then
        error "Can't export: IMAGE_NAME not set!"
    fi

    mkdir -p "${DEPLOY_DIR}"

    CLEAN=1
    EXPORT_DIR=${SOURCE_DIR}
    # shellcheck source=/dev/null
    source "${EXPORT_DIR}/defconfig"
    EXPORT_ROOTFS_DIR=${ROOTFS_DIR}
    build_Imagefile "export/${EXPORT_TYPE}"
fi

