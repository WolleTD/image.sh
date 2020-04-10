#!/bin/bash

error() { echo "$1" 1>&2; exit 1; }

[ "$(id -u)" == "0" ] || error "Please run as root"

export BASE_DIR="$(realpath "${BASH_SOURCE[0]%/*}")"
export GIT_HASH="$(git --git-dir="${BASE_DIR}/.git" rev-parse HEAD)"
export SCRIPT_DIR="${BASE_DIR}/scripts"
export PATH="${SCRIPT_DIR}:$PATH"
export CACHE_DIR="${CACHE_DIR:-"${BASE_DIR}/work"}"

OPTS=f:t:h
LONGOPTS=file:,tag:,help

PARSED_OPTS=$(getopt -o ${OPTS} -l ${LONGOPTS} -n "$0" -- "$@")
eval set -- "$PARSED_OPTS"

while [[ "$1" != "--" ]]; do
	case "$1" in
    -f|--file)
        DOCKERFILE="$2"
        shift 2
        ;;
    -t|--tag)
        IMAGE_TAG="$2"
        shift 2
        ;;
    -h|--help)
        exit 0
        ;;
    *)
        echo "Programming error" >&2
        exit 1
        ;;
	esac
done

# Defaults for optional arguments
DOCKERFILE=${DOCKERFILE:-Dockerfile}

# Positional arguments
shift # --

COMMAND="$1"; shift
[[ "${COMMAND}" == "build" ]] || error "NOT IMPLEMENT: ${COMMAND}"

CONTEXT="$1"; shift
[[ -n "${CONTEXT}" ]] || error "Build context path required!"

# Check if paths are valid
if [[ "${DOCKERFILE}" == "-" ]]; then
    DOCKERFILE=STDIN
    SOURCE_FILE=/dev/stdin
elif [ -f "${DOCKERFILE}" ]; then
    SOURCE_FILE="$(realpath "${DOCKERFILE}")"
else
    error "Can't find ${DOCKERFILE}!"
fi

if [ -d "${CONTEXT}" ]; then
    SOURCE_DIR="$(realpath "${CONTEXT}")"
else
    error "Can't find ${CONTEXT}!"
fi


declare -A commands
# shellcheck source=scripts/commands
source "${SCRIPT_DIR}/commands"


# Starting the build

echo "Building ${DOCKERFILE} in ${CONTEXT}"
pushd "${SOURCE_DIR}" > /dev/null

# IMAGE_DIR probably has to move into the loop
# as each command becomes a layer.
# Requires valid caching first
IMAGE_DIR="${CACHE_DIR}/${CONTEXT}"
[ -f "${IMAGE_DIR}/image.sh.lock" ] &&     \
    error "Image ${CONTEXT}: Directory busy (image.sh.lock exists)"

# [ "${CLEAN}" = "1" ] && rm -rf "${IMAGE_DIR}"
# Always clean for the moment
rm -rf "${IMAGE_DIR}"

mkdir -p "${IMAGE_DIR}"
touch "${IMAGE_DIR}/image.sh.lock"
LOG_FILE="${IMAGE_DIR}/image.sh.log"
ROOTFS_DIR="${IMAGE_DIR}/rootfs"

# Parse Dockerfile. sed cuts out blank lines and comments,
# awk joins lines ending with a \. The result is read into
# $cmd and $args and basically executed like that.
# $cmds are implemented in scripts/commands
sed '/^$/d;/^\s*#/d' "${SOURCE_FILE}" | \
    awk '!/\\$/{print l$0;l=""}/\\$/{sub(/\\$/,"",$0);l=l$0}' | \
    while read -r cmd args
do
    if [[ -z "${commands[$cmd]}" ]]; then
        rm "${IMAGE_DIR}/image.sh.lock"
        error "Unknown command $cmd!"
    fi
    if ! "${commands[$cmd]}" "${args}"; then
        rm "${IMAGE_DIR}/image.sh.lock"
        error "Command ${cmd} ${args} failed!"
    fi
    echo "${cmd} ${args}" >> "${IMAGE_DIR}/image.sh.cache"
done

rm -f "${IMAGE_DIR}/image.sh.lock"
popd > /dev/null
echo "Finished building ${DOCKERFILE} in ${CONTEXT}"

