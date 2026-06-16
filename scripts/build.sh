#!/usr/bin/env bash
# Build a runnable GrammaGem.app bundle from the SwiftPM executable.
# Usage: ./scripts/build.sh   (run from the mac/ directory)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="release"
APP="GrammaGem.app"
BUILD_DIR=".build/${CONFIG}"
DIST="dist"

echo "==> Compiling (${CONFIG})"
swift build -c "${CONFIG}"

echo "==> Assembling ${APP}"
rm -rf "${DIST}/${APP}"
mkdir -p "${DIST}/${APP}/Contents/MacOS" "${DIST}/${APP}/Contents/Resources"

cp "${BUILD_DIR}/GrammaGem" "${DIST}/${APP}/Contents/MacOS/GrammaGem"
cp "AppSupport/Info.plist" "${DIST}/${APP}/Contents/Info.plist"
cp "AppSupport/AppIcon.icns" "${DIST}/${APP}/Contents/Resources/AppIcon.icns"

echo "==> Built ${DIST}/${APP}"
echo "    Run with: open \"${DIST}/${APP}\"   (grant Accessibility on first launch)"
