debian_release="stable"
debian_source="http://deb.debian.org/debian/"

debootstrap_args+=(--arch armhf)
debootstrap_args+=(--components "main,contrib,non-free")
