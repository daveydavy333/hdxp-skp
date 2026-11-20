SRC="${HDX_SRC:-/hdxp/src/skp-util-kitty-src}"
VER=0.51.0
SHA256=084807db816a3de9f1a253eff232f17fe9f76ccd77da8101511f830431097ecf
TARBALL="kitty-$VER.tar.xz"
NF_VER=v3.5.1
NF_SHA256=01172f37db8543edb102e5cb5c64101c9f4686630804d49b419aa07b23a69996
NF_TARBALL=NerdFontsSymbolsOnly.tar.xz
# fail early with a clear message instead of deep inside setup.py
for m in libcrypto gl egl wayland-egl wayland-client xkbcommon harfbuzz lcms2 libxxhash; do
  pkg-config --exists "$m" || { echo "util-kitty: pkg-config module $m not found" >&2; exit 1; }
done
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/kovidgoyal/kitty/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -f "$NF_TARBALL" ] || curl -fL -o "$NF_TARBALL" "https://github.com/ryanoasis/nerd-fonts/releases/download/$NF_VER/$NF_TARBALL"
echo "$NF_SHA256  $NF_TARBALL" | sha256sum -c -
[ -d "kitty-$VER" ] || tar xf "$TARBALL"
cd "kitty-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# built-in Symbols Nerd Font Mono: put it where setup.py looks first (skips the fc-list lookup)
mkdir -p fonts
[ -f fonts/SymbolsNerdFontMono-Regular.ttf ] || tar xf "../$NF_TARBALL" -C fonts SymbolsNerdFontMono-Regular.ttf
chmod 644 fonts/SymbolsNerdFontMono-Regular.ttf
# Wayland only: drop the X11 backend from the glfw build (X11 libraries are not on HDXI)
sed -i "s/'cocoa' if is_macos else 'x11 wayland'/'cocoa' if is_macos else 'wayland'/" setup.py
grep -q "'cocoa' if is_macos else 'wayland'" setup.py
# go downloads kitty's modules on the first build, so this needs network
GOPATH="$SRC/gopath"
GOCACHE="$SRC/gocache"
GOTOOLCHAIN=local
GOFLAGS=-buildvcs=false
export GOPATH GOCACHE GOTOOLCHAIN GOFLAGS
rm -rf "$SRC/pkg"
# --ignore-compiler-warnings: kitty builds with -Werror and new gcc versions warn
python3 setup.py linux-package --prefix="$SRC/pkg" --libdir-name=lib \
  --update-check-interval=0 --ignore-compiler-warnings
[ -e "$SRC/pkg/bin/kitty" ]
$SU cp -a "$SRC/pkg/." /usr/local/
sync
[ -e /usr/local/bin/kitty ]
