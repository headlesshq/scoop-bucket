#!/usr/bin/env bash
# Renders bucket/headlessmc.json for a HeadlessMc release.
# Usage: update-headlessmc.sh [tag]   (defaults to the latest release)
# Requires: gh (authenticated via GH_TOKEN), curl, sha256sum or shasum.
set -euo pipefail

REPO="headlesshq/headlessmc"
MANIFEST="$(cd "$(dirname "$0")/../.." && pwd)/bucket/headlessmc.json"
TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  TAG="$(gh release view --repo "$REPO" --json tagName --jq .tagName)"
fi
VERSION="${TAG#v}"
URL="https://github.com/$REPO/releases/download/$TAG/headlessmc-launcher-windows-x64.exe"

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi
}

echo "Hashing headlessmc-launcher-windows-x64.exe ($TAG)" >&2
SHA="$(curl -fsSL --retry 3 "$URL" | sha256)"

# checkver and autoupdate let Scoop's own tooling (bin/checkver.ps1) update the manifest as well.
# The url has no architecture block: there is only an x64 executable, which Windows on ARM runs through emulation.
# "#/headlessmc.exe" renames the download, so the command is "headlessmc".
cat > "$MANIFEST" <<JSON
{
    "version": "$VERSION",
    "description": "Command-line launcher for Minecraft Java Edition",
    "homepage": "https://headlesshq.github.io/headlessmc/",
    "license": "MIT",
    "url": "$URL#/headlessmc.exe",
    "hash": "$SHA",
    "bin": "headlessmc.exe",
    "checkver": {
        "url": "https://api.github.com/repos/$REPO/releases/latest",
        "jsonpath": "\$.tag_name"
    },
    "autoupdate": {
        "url": "https://github.com/$REPO/releases/download/\$version/headlessmc-launcher-windows-x64.exe#/headlessmc.exe"
    }
}
JSON

echo "Updated $MANIFEST to $VERSION" >&2
