# HDXI skunkports (skp)

Skunkports are the extremely heavy or experimental ports that do not belong in the
main ports tree (hdxp): huge compile times, huge dependency trees, or software that
barely fits a small musl distribution. Nothing here is supported. It may break.

Install one with the skp/ prefix:

    hdx i skp/devel-mesa

Layout matches hdxp: `pkgs/<class>-<name>/` with make.sh, deps, info, and an extra
`warning` file shown before the build starts.

Rules:
- a skunkport may depend on normal ports, but a normal port never depends on a skunkport
- install markers are written as skp-<class>-<name> in /hdxp/installed
- sources go in /hdxp/src/skp-<class>-<name>-src

Cloned to /hdxp/skp from https://github.com/daveydavy333/hdxp-skp
