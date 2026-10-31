#!/usr/bin/env bash
# Build a Debian package for SwimSet.
#
#   bash packaging/linux/build-deb.sh
#
# Output: build/swimset_<version>_all.deb
# Requires: dpkg-deb (part of dpkg), install, du.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "error: dpkg-deb is required (sudo apt install dpkg-dev)" >&2
  exit 1
fi

VERSION="${VERSION:-$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' package.json | head -n1)}"
VERSION="${VERSION:-1.0.0}"
ARCH="${ARCH:-all}"
PKG_NAME="swimset_${VERSION}_${ARCH}"
BUILD_DIR="$ROOT/build/deb"
PKG_DIR="$BUILD_DIR/$PKG_NAME"
OUT_DIR="$ROOT/build"

echo "Building $PKG_NAME …"
rm -rf "$PKG_DIR"
mkdir -p \
  "$PKG_DIR/DEBIAN" \
  "$PKG_DIR/usr/bin" \
  "$PKG_DIR/usr/share/swimset" \
  "$PKG_DIR/usr/share/applications" \
  "$PKG_DIR/usr/share/icons/hicolor/512x512/apps" \
  "$PKG_DIR/usr/share/icons/hicolor/192x192/apps" \
  "$PKG_DIR/usr/share/icons/hicolor/32x32/apps" \
  "$PKG_DIR/usr/share/doc/swimset"

# --- application payload ---------------------------------------------------
for item in index.html manifest.webmanifest sw.js css js icons; do
  if [ ! -e "$ROOT/$item" ]; then
    echo "error: missing $item" >&2
    exit 1
  fi
  cp -R "$ROOT/$item" "$PKG_DIR/usr/share/swimset/"
done

# The icon generator script and SVGs are not needed at runtime, but the SVGs
# are tiny and useful for theming; keep everything under icons/.
find "$PKG_DIR/usr/share/swimset" -type f -exec chmod 0644 {} +
find "$PKG_DIR/usr/share/swimset" -type d -exec chmod 0755 {} +

# --- launcher, desktop entry, icons, docs ----------------------------------
install -m 0755 "$ROOT/packaging/linux/swimset" "$PKG_DIR/usr/bin/swimset"
install -m 0644 "$ROOT/packaging/linux/swimset.desktop" "$PKG_DIR/usr/share/applications/swimset.desktop"
install -m 0644 "$ROOT/icons/icon-512.png" "$PKG_DIR/usr/share/icons/hicolor/512x512/apps/swimset.png"
install -m 0644 "$ROOT/icons/icon-192.png" "$PKG_DIR/usr/share/icons/hicolor/192x192/apps/swimset.png"
install -m 0644 "$ROOT/icons/favicon-32.png" "$PKG_DIR/usr/share/icons/hicolor/32x32/apps/swimset.png"
install -m 0644 "$ROOT/README.md" "$PKG_DIR/usr/share/doc/swimset/README.md"
install -m 0644 "$ROOT/LICENSE" "$PKG_DIR/usr/share/doc/swimset/copyright"

INSTALLED_SIZE="$(du -sk --exclude=DEBIAN "$PKG_DIR" | cut -f1)"

# --- control metadata -------------------------------------------------------
cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: swimset
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_SIZE
Depends: python3 (>= 3.8)
Recommends: chromium | chromium-browser | google-chrome-stable | firefox-esr
Maintainer: SwimSet <swimset@localhost>
Homepage: https://github.com/mob5824m-wq/SwimSet
Description: swim practice maker for coaches and swimmers
 SwimSet builds swim practices set by set: reps, distance, stroke,
 equipment and rest. It calculates send-offs from a base pace, totals
 the session, prints a deck sheet and turns the practice into a
 poolside timer with audio cues.
 .
 The app is a self-contained web application served from localhost, so
 it also works offline and can be installed on Android, Chromebooks and
 desktop browsers. This package adds a launcher to the applications
 menu and a local offline copy of the app.
EOF

mkdir -p "$OUT_DIR"
dpkg-deb --root-owner-group --build "$PKG_DIR" "$OUT_DIR/${PKG_NAME}.deb" >/dev/null

echo
echo "Built: build/${PKG_NAME}.deb"
echo "Install with:  sudo apt install ./build/${PKG_NAME}.deb"
echo "Then launch SwimSet from your applications menu, or run: swimset"
