#!/usr/bin/env bash
# Package a signed build for distribution and update the Sparkle appcast hosted
# on GitHub Releases (zero hosting cost). Run after sign-notarize.sh.
#
# This is a documented scaffold — wire it to your Sparkle EdDSA key + repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/GrammaGem.app"
VERSION="${1:?Usage: release.sh <version> e.g. 0.1.0}"
DMG="$ROOT/dist/GrammaGem-$VERSION.dmg"

echo "▸ Creating DMG for $VERSION…"
# hdiutil create -volname "GrammaGem" -srcfolder "$APP" -ov -format UDZO "$DMG"   # TODO: enable
echo "  (DMG creation stubbed — uncomment hdiutil line)"

cat <<'NOTE'
▸ Sparkle appcast (TODO):
  1. Sign the update:  ./bin/sign_update dist/GrammaGem-<ver>.dmg
     (Sparkle's sign_update tool, using your EdDSA private key)
  2. Add an <item> to appcast.xml with the version, URL (GitHub Releases asset),
     length, and sparkle:edSignature.
  3. Upload the DMG + appcast.xml to a GitHub Release.
  The app's SUFeedURL points at the raw appcast.xml on GitHub — $0 hosting.

▸ Distribution touchpoints (all $0 marginal cost):
  - Model weights:  Hugging Face CDN
  - Updates:        GitHub Releases + Sparkle
  - Licensing:      Lemon Squeezy License API (% per sale only)
NOTE

echo "✓ Release steps printed for $VERSION"
