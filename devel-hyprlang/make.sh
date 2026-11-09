SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprlang-src}"
# hyprlang 0.6.8, the commit from Hyprland v0.56.2's flake.lock
COMMIT=090117506ddc3d7f26e650ff344d378c2ec329cc
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprlang ] || git clone https://github.com/hyprwm/hyprlang
cd hyprlang
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" --target hyprlang
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
