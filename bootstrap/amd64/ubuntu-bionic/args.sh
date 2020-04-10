debian_release="bionic"
debian_source="http://archive.ubuntu.com/ubuntu/"

debootstrap_args+=(--components "main,restricted,universe,multiverse")
