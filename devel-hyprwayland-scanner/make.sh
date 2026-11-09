SRC="${HDX_SRC:-/hdxp/src/skp-devel-hyprwayland-scanner-src}"
# hyprwayland-scanner 0.4.6, the commit from Hyprland v0.56.2's flake.lock
COMMIT=b8632713a6beaf28b56f2a7b0ab2fb7088dbb404
mkdir -p "$SRC"
cd "$SRC"
[ -d hyprwayland-scanner ] || git clone https://github.com/hyprwm/hyprwayland-scanner
cd hyprwayland-scanner
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" 
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
