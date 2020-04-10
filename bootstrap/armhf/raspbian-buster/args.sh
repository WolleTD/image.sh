debian_release="stable"
debian_source="http://raspbian.raspberrypi.org/raspbian/"

debootstrap_args+=(--arch armhf)
debootstrap_args+=(--components "main,contrib,non-free")
