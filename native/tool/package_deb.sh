#!/usr/bin/env bash
# Builds a self-contained .deb from the Flutter Linux release bundle.
set -euo pipefail

VERSION="${1:-2.0.0}"
ARCH="${2:-amd64}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
OUT="$ROOT/build/deb"
PKG="$OUT/swimset_${VERSION}_${ARCH}"

if [[ ! -x "$BUNDLE/swimset" ]]; then
  echo "Missing Linux bundle at $BUNDLE — run 'flutter build linux --release' first." >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p \
  "$PKG/DEBIAN" \
  "$PKG/opt/swimset" \
  "$PKG/usr/bin" \
  "$PKG/usr/share/applications" \
  "$PKG/usr/share/icons/hicolor/512x512/apps" \
  "$PKG/usr/share/doc/swimset"

cp -R "$BUNDLE/." "$PKG/opt/swimset/"
chmod 0755 "$PKG/opt/swimset/swimset"

cat > "$PKG/usr/bin/swimset" <<'LAUNCHER'
#!/bin/sh
exec /opt/swimset/swimset "$@"
LAUNCHER
chmod 0755 "$PKG/usr/bin/swimset"

cat > "$PKG/usr/share/applications/swimset.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=SwimSet
GenericName=Swim practice maker
Comment=Build, print and run swim practices
Exec=swimset
Icon=swimset
Terminal=false
Categories=Utility;Education;
Keywords=swimming;coach;practice;timer;workout;
StartupWMClass=swimset
DESKTOP
chmod 0644 "$PKG/usr/share/applications/swimset.desktop"

cp "$ROOT/branding/swimset.png" "$PKG/usr/share/icons/hicolor/512x512/apps/swimset.png"
cp "$ROOT/../LICENSE" "$PKG/usr/share/doc/swimset/copyright" 2>/dev/null || true

INSTALLED_SIZE="$(du -sk "$PKG/opt" | cut -f1)"
cat > "$PKG/DEBIAN/control" <<CONTROL
Package: swimset
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Installed-Size: ${INSTALLED_SIZE}
Maintainer: mob5824 <mob5824@users.noreply.github.com>
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libc6, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Recommends: gstreamer1.0-plugins-good
Description: Native swim practice maker
 Build a swim practice set by set, calculate send-offs from a base pace,
 print a deck sheet as PDF, and run the session poolside with a rep-by-rep
 timer, countdown beeps and a plan.
 .
 A native Flutter app: no browser and no network access required.
CONTROL
chmod 0644 "$PKG/DEBIAN/control"

(cd "$PKG" && find opt usr -type f -print0 | xargs -0 md5sum > DEBIAN/md5sums)
chmod 0644 "$PKG/DEBIAN/md5sums"

dpkg-deb --root-owner-group --build "$PKG" "$OUT/swimset_${VERSION}_${ARCH}.deb"
echo "Built: $OUT/swimset_${VERSION}_${ARCH}.deb"
dpkg-deb --info "$OUT/swimset_${VERSION}_${ARCH}.deb" | sed -n '1,20p'
