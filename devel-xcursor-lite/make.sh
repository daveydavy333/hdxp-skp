SRC="${HDX_SRC:-/hdxp/src/skp-devel-xcursor-lite-src}"
VER=1.2.3
SHA256=74e72da27e61cc2cfd2e267c14f500ea47775850048ee0b00362a55c9b60ee9b
TARBALL="libxcursor-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libx/libxcursor/libxcursor_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libXcursor-$VER" ] || tar -xf "$TARBALL"
cd "libXcursor-$VER"
rm -rf lite
mkdir -p lite/src lite/inc/X11/Xcursor
# generate the X-free subset: header without Display/Cursor declarations, library.c without its Display functions
cat > xform.py <<'PYEOF'
import re,sys
S=sys.argv[1]; D=sys.argv[2]
# ---- public header: drop X includes and every declaration that needs Display/Cursor
h=open(S+'/include/X11/Xcursor/Xcursor.h').read()
h=h.replace('#include <X11/Xfuncproto.h>\n','').replace('#include <X11/Xlib.h>\n','')
h=h.replace('_XFUNCPROTOBEGIN','#ifdef __cplusplus\nextern "C" {\n#endif',1)
h=h.replace('_XFUNCPROTOEND','#ifdef __cplusplus\n}\n#endif',1)
# drop struct typedefs that need Display/Cursor
for name in ('XcursorCursors','XcursorAnimate'):
    h,n=re.subn(r'typedef struct _%s \{.*?\} %s;\n'%(name,name),'',h,flags=re.S); assert n==1,name
a=h.index('#ifdef __cplusplus\nextern "C" {'); b=h.index('#ifdef __cplusplus\n}')
body=h[a:b]
head,rest=body.split('\n',3)[0:3],body.split('\n',3)[3]
parts=rest.split(';')
keep=[]
for p in parts[:-1]:
    if re.search(r'\bDisplay\b|\bXImage\b|XcursorCursors|XcursorAnimate|^\s*Cursor\b|\n\s*Cursor\b|\bCursor\s*\n',p):
        # keep any leading comment-less remains out: drop whole chunk
        continue
    keep.append(p)
body=body.split('\n',3)[0]+'\n'+body.split('\n',3)[1]+'\n'+body.split('\n',3)[2]+'\n'+';'.join(keep)+';\n\n'
h=h[:a]+body+h[b:]
open(D+'/inc/X11/Xcursor/Xcursor.h','w').write(h)
# ---- sources
def strip_display_funcs(t):
    out=[];i=0
    lines=t.split('\n')
    res=[];k=0
    while k<len(lines):
        if lines[k]=='{':
            # signature = preceding lines already in res back to blank line or '}'
            j=len(res)
            while j>0 and res[j-1].strip() not in ('','}') and not res[j-1].startswith('#') and not res[j-1].startswith('/*') and not res[j-1].startswith(' *'): j-=1
            sig='\n'.join(res[j:])
            e=k
            while lines[e]!='}': e+=1
            if re.search(r'\bDisplay\b',sig):
                del res[j:]; k=e+1; continue
            res.extend(lines[k:e+1]); k=e+1; continue
        res.append(lines[k]); k+=1
    return '\n'.join(res)
for f in ('file.c','library.c'):
    t=open(S+'/src/'+f).read()
    if f=='library.c': t=strip_display_funcs(t)
    open(D+'/src/'+f,'w').write(t)
open(D+'/src/xcursorint.h','w').write('''#ifndef _XCURSORINT_H_
#define _XCURSORINT_H_
#include "Xcursor.h"
#include <fcntl.h>
#ifdef O_CLOEXEC
#define FOPEN_CLOEXEC "e"
#else
#define FOPEN_CLOEXEC ""
#endif
#define T_CALLED(func) ""
#define enterFunc(params) /* nothing */
#define traceOpts(params) /* nothing */
#define returnAddr(addr) return (addr)
#define returnCode(code) return (code)
#define returnLong(code) return (code)
#define returnUint(code) return (code)
#define returnVoid()     return
#define NonNull(p) ((p) != NULL ? (p) : "<null>")
#endif
''')
PYEOF
python3 xform.py "$PWD" "$PWD/lite" || exit 1
cd lite
cc -O2 -Wall -fPIC -shared -Wl,-soname,libXcursor.so.1 \
  -DXCURSORPATH='"~/.icons:/usr/share/icons:/usr/local/share/icons:/usr/share/pixmaps"' \
  -Iinc/X11/Xcursor -Isrc -o libXcursor.so.1.0.0 src/file.c src/library.c || exit 1
ln -sf libXcursor.so.1.0.0 libXcursor.so.1
ln -sf libXcursor.so.1 libXcursor.so
cat > xcursor.pc <<'EOF'
prefix=/usr/local
libdir=${prefix}/lib
includedir=${prefix}/include

Name: Xcursor
Description: X Cursor library (X11-free subset: cursor file and theme loading only)
Version: 1.2.3
Cflags: -I${includedir}
Libs: -L${libdir} -lXcursor
EOF
# smoke test against the library we just built
cat > smoke.c <<'EOF'
#include <stdio.h>
#include <X11/Xcursor/Xcursor.h>
int main(void) { const char *p = XcursorLibraryPath(); if (!p || !*p) return 1; printf("xcursor path: %s\n", p); return 0; }
EOF
cc -Iinc -o smoke smoke.c -L. -lXcursor || exit 1
LD_LIBRARY_PATH="$PWD" ./smoke || { echo "xcursor-lite smoke test failed"; exit 1; }
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /usr/local/lib/pkgconfig /usr/local/include/X11/Xcursor
$SU cp libXcursor.so.1.0.0 /usr/local/lib/
$SU ln -sf libXcursor.so.1.0.0 /usr/local/lib/libXcursor.so.1
$SU ln -sf libXcursor.so.1 /usr/local/lib/libXcursor.so
$SU cp inc/X11/Xcursor/Xcursor.h /usr/local/include/X11/Xcursor/Xcursor.h
$SU cp xcursor.pc /usr/local/lib/pkgconfig/xcursor.pc
