SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprutils-src}"
# hyprutils 0.14.0, the commit from Hyprland v0.56.2's flake.lock
COMMIT=5a7b8cf221914ce4714407950e4ffbdddcd8b66f
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprutils ] || git clone https://github.com/hyprwm/hyprutils
cd hyprutils
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" --target hyprutils
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
