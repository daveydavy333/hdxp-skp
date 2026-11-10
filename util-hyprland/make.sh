SRC="${HDX_SRC:-/hdxp/src/skp-util-hyprland-src}"
# Hyprland v0.56.2
COMMIT=efb50993780079460b0cbed1363e2166a2de1d9f
# glaze v7.2.0 (header-only JSON library, normally fetched by Hyprland's cmake at configure time)
GLAZE_COMMIT=b518eec7a22e56ffa238b072c07f47efa7cea97f
# fail early, before the long clone and build
pkg-config --atleast-version=1.11.0 xkbcommon || { echo "Hyprland needs xkbcommon >= 1.11"; exit 1; }
pkg-config --atleast-version=1.22.91 wayland-server || { echo "Hyprland needs wayland-server >= 1.22.91"; exit 1; }
mkdir -p "$SRC"
cd "$SRC"
[ -d glaze ] || git clone https://github.com/stephenberry/glaze
git -C glaze fetch --tags
git -C glaze checkout -f "$GLAZE_COMMIT"
[ "$(git -C glaze rev-parse HEAD)" = "$GLAZE_COMMIT" ] || { echo "glaze commit mismatch"; exit 1; }
[ -d Hyprland ] || git clone https://github.com/hyprwm/Hyprland
cd Hyprland
git fetch --tags
git checkout -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
# hyprland-protocols and udis86 are git submodules, pinned by this commit
git submodule update --init subprojects/hyprland-protocols subprojects/udis86 || { echo "submodule update failed"; exit 1; }
# std::ranges::starts_with is rejected by this toolchain; Hyprland uses it once, so replace it with an equivalent
sed -i 's#std::ranges::starts_with(str_view, prefixes)#(std::ranges::size(str_view) >= prefixes.size() \&\& std::ranges::equal(str_view | std::views::take(prefixes.size()), prefixes))#' src/helpers/MiscFunctions.cpp
grep -q 'ranges::size(str_view) >= prefixes.size()' src/helpers/MiscFunctions.cpp || { echo "MiscFunctions.cpp patch failed"; exit 1; }
# XWM.cpp includes two xcb headers before its NO_XWAYLAND guard, so it needs xcb even with XWayland off: move them inside the guard
sed -i '5,6{s|^#include <xcb/xfixes.h>$|#ifndef NO_XWAYLAND\n#include <xcb/xfixes.h>|;s|^#include <xcb/xproto.h>$|#include <xcb/xproto.h>\n#endif|}' src/xwayland/XWM.cpp
sed -n 5,8p src/xwayland/XWM.cpp | grep -q '^#ifndef NO_XWAYLAND$' || { echo "XWM.cpp patch failed"; exit 1; }
# HDX_KEEP_BUILD=1 keeps the previous build directory, so a retry resumes instead of recompiling everything
[ -n "$HDX_KEEP_BUILD" ] || rm -rf build
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DNO_XWAYLAND=1 -DNO_SYSTEMD=1 -DNO_HYPRPM=1 \
  -DFETCHCONTENT_SOURCE_DIR_GLAZE="$SRC/glaze" -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build -j"${HDX_JOBS:-2}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU cmake --install build
[ -x /usr/local/bin/Hyprland ] && [ -x /usr/local/bin/hyprctl ] || { echo "Hyprland or hyprctl was not installed"; exit 1; }
# Hyprland refuses to start without XDG_RUNTIME_DIR, even for --version; this check only warns, the install is done at this point
T="$(mktemp -d)"
XDG_RUNTIME_DIR="$T" /usr/local/bin/Hyprland --version || echo "warning: Hyprland --version did not run (a missing library?)"
rm -rf "$T"
