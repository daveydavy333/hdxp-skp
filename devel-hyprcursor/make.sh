SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprcursor-src}"
# hyprcursor 0.1.13, the commit from Hyprland v0.56.2's flake.lock
COMMIT=39435900785d0c560c6ae8777d29f28617d031ef
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprcursor ] || git clone https://github.com/hyprwm/hyprcursor
cd hyprcursor
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" --target hyprcursor hyprcursor-util
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
