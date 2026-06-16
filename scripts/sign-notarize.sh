#!/usr/bin/env bash
# Codesign (Hardened Runtime) + notarize + staple the GrammaGem.app bundle.
# Requires the Apple Developer Program ($99/yr) — a FIXED cost, not per-user.
#
# Prereqs (set as env vars or fill in):
#   DEV_ID         e.g. "Developer ID Application: Your Name (TEAMID)"
#   KEYCHAIN_PROFILE  a stored notarytool profile (xcrun notarytool store-credentials)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/GrammaGem.app"
ENTITLEMENTS="$ROOT/AppSupport/GrammaGem.entitlements"

: "${DEV_ID:?Set DEV_ID to your Developer ID Application identity}"
: "${KEYCHAIN_PROFILE:?Set KEYCHAIN_PROFILE to your stored notarytool profile}"

echo "▸ Codesigning with Hardened Runtime…"
codesign --force --deep --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$DEV_ID" \
  "$APP"

echo "▸ Zipping for notarization…"
ZIP="$ROOT/dist/GrammaGem.zip"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Submitting to Apple notary service…"
xcrun notarytool submit "$ZIP" --keychain-profile "$KEYCHAIN_PROFILE" --wait

echo "▸ Stapling ticket…"
xcrun stapler staple "$APP"

echo "✓ Signed, notarized, and stapled: $APP"
