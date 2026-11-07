[ -n "$HDX_BOOT_ANYWHERE" ] || mountpoint -q /boot || { echo "mount your ESP at /boot first (or set HDX_BOOT_ANYWHERE=1)"; exit 1; }
VER=6.18.55-gnu
KBASE=6.18
TAR="linux-libre-$KBASE-gnu.tar.xz"
TAR_SHA=4b38d5ba30c8cb0a99cc0380e61092b626d273305d6ef866286cecfec9cd8593
PATCH="patch-$KBASE-gnu-$VER.bz2"
PATCH_SHA=74291fb3e7caf72a291b24f0761fd1fd308bb22a71ac4d46634ade0793f9308c
BASEURL=https://linux-libre.fsfla.org/pub/linux-libre/releases
SRC="${HDX_SRC:-/hdxp/src/skp-base-linux-libre-src}"

command -v patch >/dev/null || { echo "this port needs patch(1) and it is not installed"; exit 1; }

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fLO "$BASEURL/$KBASE-gnu/$TAR"
echo "$TAR_SHA  $TAR" | sha256sum -c -
[ -f "$PATCH" ] || curl -fLO "$BASEURL/$VER/$PATCH"
echo "$PATCH_SHA  $PATCH" | sha256sum -c -

# linux-libre ships one tarball per major version plus a patch for every point release
TREE="linux-libre-$VER"
if [ ! -d "$TREE" ]; then
    rm -rf "linux-$KBASE"
    tar -xf "$TAR"
    [ -d "linux-$KBASE" ] || { echo "unexpected tarball layout:"; ls; exit 1; }
    mv "linux-$KBASE" "$TREE"
    ( cd "$TREE" && bzip2 -dc "../$PATCH" | patch -p1 ) || { rm -rf "$TREE"; echo "failed to apply $PATCH"; exit 1; }
fi
cd "$TREE"

make defconfig kvm_guest.config
for o in EXT4_FS VIRTIO_BLK VIRTIO_PCI VIRTIO_NET DEVTMPFS UEVENT_HELPER; do
    scripts/config --enable "$o"
done
scripts/config --disable DEBUG_INFO_BTF
scripts/config --enable FB --enable DRM_FBDEV_EMULATION --enable FRAMEBUFFER_CONSOLE --enable FRAMEBUFFER_CONSOLE_DETECT_PRIMARY --enable SYSFB_SIMPLEFB --enable DRM_SIMPLEDRM
scripts/config --enable MMC --enable MMC_BLOCK --enable MMC_SDHCI --enable MMC_SDHCI_PCI --enable BLK_DEV_SD --enable SATA_AHCI --enable BLK_DEV_NVME --enable USB_XHCI_HCD --enable USB_XHCI_PCI --enable USB_EHCI_HCD --enable USB_EHCI_PCI --enable USB_STORAGE --enable USB_HID --enable HID_GENERIC --enable KEYBOARD_ATKBD
# no firmware is built in: this kernel refuses non-free blobs. wifi is ath9k (pci, needs no firmware);
# iwlwifi, ath10k and amdgpu are left out on purpose (amdgpu built in without its firmware takes the screen
# over from simpledrm and then fails, which would leave no display at all)
scripts/config --enable PCI --enable WIRELESS --enable CFG80211 --enable MAC80211 --enable RFKILL --enable WLAN --enable WLAN_VENDOR_ATH --enable ATH9K
# intel graphics: i915 drives the screen without any firmware
scripts/config --enable DRM_I915
# i2c-hid touchpads behind the intel LPSS controller (same options as base-kernel)
TP_OPTS="COMMON_CLK PINCTRL I2C I2C_DESIGNWARE_CORE I2C_DESIGNWARE_PLATFORM PINCTRL_TIGERLAKE MFD_INTEL_LPSS_PCI MFD_INTEL_LPSS_ACPI I2C_HID_ACPI HID_MULTITOUCH INPUT_MOUSE"
for o in $TP_OPTS; do
    scripts/config --enable "$o"
done
scripts/config --set-str UEVENT_HELPER_PATH ""
make olddefconfig
for o in $TP_OPTS; do
    grep -q "^CONFIG_$o=y" .config || echo "note: CONFIG_$o did not stay enabled (touchpad support may be incomplete)"
done

# the files below are named after VER, so make sure the tree really builds that version
REL=$(make -s kernelrelease)
[ "$REL" = "$VER" ] || { echo "error: this tree builds kernel $REL, but make.sh expects $VER"; exit 1; }

make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /boot
$SU cp arch/x86/boot/bzImage "/boot/vmlinuz-$VER"
# /boot/vmlinuz (base-kernel) is left alone; this kernel is /boot/vmlinuz-libre
$SU cp arch/x86/boot/bzImage /boot/vmlinuz-libre
$SU cp .config "/boot/config-$VER"
$SU cp System.map "/boot/System.map-$VER"
$SU make modules_install

echo "linux-libre $VER installed as /boot/vmlinuz-libre. add a boot entry for it (see the warning text); /boot/vmlinuz is untouched."
