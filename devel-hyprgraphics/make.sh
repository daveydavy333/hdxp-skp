SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprgraphics-src}"
# hyprgraphics 0.5.1, the commit from Hyprland v0.56.2's flake.lock
COMMIT=8699c38f0e4a1ca3bfc84f84ba020509ced1f133
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprgraphics ] || git clone https://github.com/hyprwm/hyprgraphics
cd hyprgraphics
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" --target hyprgraphics
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
