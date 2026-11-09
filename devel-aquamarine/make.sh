SRC="${HDX_SRC:-/hdxp/src/skp-devel-aquamarine-src}"
# aquamarine 0.14.0, the commit from Hyprland v0.56.2's flake.lock
COMMIT=1a10fe26a9f7d989c359e6a9ea61aa2e44d06c36
mkdir -p "$SRC"
cd "$SRC"
[ -d aquamarine ] || git clone https://github.com/hyprwm/aquamarine
cd aquamarine
git fetch --tags
git checkout -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
# our mesa has no glvnd, so there is no libOpenGL and no OpenGL::OpenGL target: link the GLES3 one instead
sed -i 's/OpenGL::EGL OpenGL::OpenGL PkgConfig::deps/OpenGL::EGL OpenGL::GLES3 PkgConfig::deps/' CMakeLists.txt
grep -q 'OpenGL::EGL OpenGL::GLES3 PkgConfig::deps' CMakeLists.txt || { echo "aquamarine OpenGL patch failed"; exit 1; }
rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-4}" --target aquamarine
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
