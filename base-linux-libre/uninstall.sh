# runs as root from the port folder, after you confirm.
# removes the kernel this port installed. the version comes from make.sh,
# so the two files can never disagree. /boot/vmlinuz (base-kernel) is never touched.
VER=$(sed -n 's/^VER=//p' ./make.sh)
case "$VER" in
    ''|*/*) echo "cannot read a sane VER from make.sh"; exit 1 ;;
esac
if [ "$(uname -r)" = "$VER" ]; then
    echo "note: $VER is the kernel you are running right now"
fi
rm -f /boot/vmlinuz-libre "/boot/vmlinuz-$VER" "/boot/config-$VER" "/boot/System.map-$VER"
rm -rf "/lib/modules/$VER"
