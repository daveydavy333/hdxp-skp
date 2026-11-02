SRC="${HDX_SRC:-/hdxp/src/skp-devel-mesa-src}"
VER=26.1.6
SHA256=5296b88a0f1e012e2cb9ada150a2bbadf728ca81e5a4fb2ab43c83a4d2158606
TARBALL="mesa-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.mesa3d.org/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "mesa-$VER" ] || tar xf "$TARBALL"
# mesa's code generators need the python modules mako, pyyaml and packaging
[ -d pyenv ] || python3 -m venv pyenv
./pyenv/bin/python -m pip install Mako==1.3.10 PyYAML==6.0.3 packaging==25.0
PATH="$SRC/pyenv/bin:$PATH"
export PATH
cd "mesa-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
# software only: softpipe (slow reference rasterizer) and virgl (QEMU virtio-gpu)
# no LLVM, so no llvmpipe and no radeonsi yet
meson setup build --prefix=/usr/local --buildtype=release \
  -Dllvm=disabled \
  -Dgallium-drivers=softpipe,virgl \
  -Dvulkan-drivers= \
  -Dplatforms=wayland \
  -Dglx=disabled -Degl=enabled -Dgbm=enabled \
  -Dgles2=enabled -Dopengl=true \
  -Dglvnd=disabled -Dvalgrind=disabled -Dlibunwind=disabled \
  -Dlmsensors=disabled -Dbuild-tests=false
meson compile -C build
$SU meson install -C build
