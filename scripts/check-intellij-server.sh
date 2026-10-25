#!/usr/bin/env bash
set -euo pipefail

api=https://open-vsx.org/api/JetBrains/intellij-server

# Resolve latest once so both platforms use the same extension release.
extension_version=latest
for arch in x64 arm64; do
  metadata=$(curl -fsSL --max-time 60 "$api/linux-$arch/$extension_version")
  extension_version=$(jq -er '.version' <<< "$metadata")
  download_url=$(jq -er '.files.download' <<< "$metadata")
  curl -fsSL --max-time 60 "$download_url" |
    bsdtar -xOf - extension/server-bundle.json |
    jq --arg platform "linux-$arch" '{platform: $platform, version, url, sha256}'
done
