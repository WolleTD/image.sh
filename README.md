# image.sh

`image.sh` is a bash-driven tool to build Linux images. It aims to provide a _simple_
layer-based approach. While they look somewhat similar, Imagefiles are no Dockerfiles
but pure bash scripts. Commands aren't layers, but directories with Imagefiles are;
it's basically a complete redesign of [pi-gen](https://github.com/RPi-Distro/pi-gen).

**WARNING: This is still work-in-progress, but feel free to contribute**

## Dependencies

`image.sh` makes heavy use of `systemd-nspawn` and `rsync` for building and uses
`parted` for creating disk images. If you are cross-building images, you will also
need `qemu-user-static` and a `binfmt_misc` configuration with the `F` flag set
(this avoids copying the binary into the build environment). You also probably
want `dosfstools` as both UEFI and most ARM bootloaders use FAT32 boot partitions.

As `image.sh` basically is a fancy bash script executor, most other requirements
are optional – even `parted` is optional, actually – but you probably want
`debootstrap` to build Debian or Ubuntu images or any other bootstrapping tool
for the distribution of your choice. `image.sh` inherited support for `quilt` patching
from pi-gen, but that's optional als well.

## Usage

`image.sh <$dir>` executes the `Imagefile` in `$dir` in the current working directory
(priority) or in the directory of `image.sh` and builds a new filesystem from this
in `$WORK_DIR/$dir/rootfs`. If `IMAGE_NAME` and `EXPORT_TYPE` are specified in the
`config` (see below) and `export/$EXPORT_TYPE` is a valid input for `image.sh`,
the corresponding `Imagefile` is used to build a target-specific non-individualized
image from the build directory in `$PWD/deploy`.

### Commands for Imagefiles

- `FROM_IMAGE <name>` currently uses `rsync` to copy another rootfs into the current
  layer. `name` has to be a valid argument vor `image.sh`.
  `image.sh` will be run for non-existent dependencies. This needs massively more
  state and error checking. Also it should use `btrfs` snapshots.
- `COPY <src> <dest>` currently uses `rsync` as well and probably has quirky, untested
  issues with trailing slashes. `dest` should be an absolute path inside the image.
- `CONFIGURE <src> <dest>` is an `envsubst` wrapper, replaces environment variables in
  `src` with their value and writes the result to `dest`, where `dest` is an absolute
  path inside the image.
- `RUN_QUILT` I'm not exactly sure, this is inherited
- `ON_CHROOT <command>` runs `command` inside the image using `systemd-nspawn`. The
  command can be ommited and `bash` will be run. This is frequently used to run
  scripts from here-docs.

## Configuration

While not pure bash and somehow bloated, I keep thinking about using Kconfig for
`image.sh` in the long-term. Or probably building a light-weight bash version.
Configuration already moved (relative to `pi-gen`) into the layers that use them.
They provide some `defconfig` which also is "documentation" of available settings.
Everything can be configured in a `config` file in the working directory. So yeah,
it's made for Kconfig, however I don't want it to become a PetaLinux.

There are also a few top-level configurations for `image.sh` itself:

 * `EXPORT_TYPE` (Default: unset)

   The export mode to use. This corresponds to a path under `export/` in the usual
   layer search paths, containing an `Imagefile`. If unset, no export is made
   and only root filesystems are built.

 * `IMAGE_NAME` (Default: unset, required on export)

   Output filename for export, without extension. This is only required when
   `EXPORT_TYPE` is set. Any modifications to this name (adding a date or a commit
   hash) should be done by the export layers.

 * `APT_PROXY` (Default: unset)

   If you require the use of an apt proxy, set it here.  This proxy setting
   will not be included in the image, making it safe to use an `apt-cacher` or
   similar package for development.

 * `WORK_DIR`  (Default: `"$BASE_DIR/work"`)

   Filesystem building directory. `$BASE_DIR` equals the directory of `image.sh`.
   Due to [this bug](https://github.com/RPi-Distro/pi-gen/issues/271), this is
   – as a pragmatic solution – required to be a `btrfs` filesystem.

 * `DEPLOY_DIR`  (Default: `"$PWD/deploy"`)

   Output directory for target system images.

## Other configuration values (for raspbian stages, this is why it needs Kconfig!)

 * `LOCALE_DEFAULT` (Default: "en_GB.UTF-8" )

   Default system locale.

 * `HOSTNAME` (Default: "raspberrypi" )

   Setting the hostname to the specified value.

 * `KEYBOARD_KEYMAP` (Default: "gb" )

   Default keyboard keymap.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/xkb-keymap` value.

 * `KEYBOARD_LAYOUT` (Default: "English (UK)" )

   Default keyboard layout.

   To get the current value from a running system, run `debconf-show
   keyboard-configuration` and look at the
   `keyboard-configuration/variant` value.

 * `TIMEZONE_DEFAULT` (Default: "Europe/London" )

   Default keyboard layout.

   To get the current value from a running system, look in
   `/etc/timezone`.

 * `FIRST_USER_NAME` (Default: "pi" )

   Username for the first user

 * `FIRST_USER_PASS` (Default: "raspberry")

   Password for the first user

 * `WPA_ESSID`, `WPA_PASSWORD` and `WPA_COUNTRY` (Default: unset)

   If these are set, they are use to configure `wpa_supplicant.conf`, so that the raspberry pi can automatically connect to a wifi network on first boot.

 * `ENABLE_SSH` (Default: `0`)

   Setting to `1` will enable ssh server for remote log in. Note that if you are using a common password such as the defaults there is a high risk of attackers taking over you RaspberryPi.


## Docker Build

Docker cannot be used for building images as it's not possbile to use
`systemd-nspawn` from inside Docker(?)

## Examples

### Raspbian Stages

Due to inheritance and as a complete example, the official raspbian build
is mirrored in the `raspbian/` directory, as well as `bootstrap/armhf/raspbian-buster`.

 - **bootstrap/armhf/raspbian-buster** - Only runs debootstrap with Raspbian sources.

 - **raspbian/base** - Configuring apt proxy, hostname and locale as well as
   installing kernel and bootloader.

 - **raspbian/lite** - This stage largely produces the Raspbian-Lite image,
   configuring users, wifi and ssh.

 - **raspbian/desktop** - desktop system. Roughly equals official stage3.

 - **raspbian/default** - Official stage4.

 - **raspbian/full** - Official stage5. Largely reprodcues the official
   Raspbian Desktop image.

