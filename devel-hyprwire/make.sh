SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprwire-src}"
# hyprwire 0.3.1, the commit from Hyprland v0.56.2's flake.lock
COMMIT=7d935bb54674aa0fbd327d2a6888bd0630079ed0
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprwire ] || git clone https://github.com/hyprwm/hyprwire
cd hyprwire
git fetch --tags
git checkout -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
