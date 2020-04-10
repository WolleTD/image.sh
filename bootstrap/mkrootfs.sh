#!/bin/bash -e
[ -z "$1" ] && exit 1
[ -f "$1/args.sh" ] || exit 1

target="$1"

tag="bootstrap/${target}"
rootfsdir="${target}/rootfs"

debootstrap_args=()

export http_proxy=${APT_PROXY}

source "${target}/args.sh"

debootstrap_args+=(--keyring "${target}/keyring.gpg")

# positionals
debootstrap_args+=("${debian_release}")
debootstrap_args+=("${rootfsdir}")
debootstrap_args+=("${debian_source}")

rm -rf "${rootfsdir}"
mkdir -p "${rootfsdir}"

debootstrap "${debootstrap_args[@]}"
ln -sf ../run/systemd/resolve/stub-resolv.conf ${rootfsdir}/etc/resolv.conf

#cat >"${target}/Dockerfile" <<EOF
image.sh build -t ${tag} -f - ${target} <<EOF
FROM scratch
ADD rootfs/ /
EOF

#img build -t "${tag}" "${builddir}"

