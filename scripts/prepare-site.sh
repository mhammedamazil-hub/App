#!/usr/bin/env bash
# Download the published static site, verify it, and prepare a Pages artifact.
set -euo pipefail
version="${DECKCRAFT_VERSION:-0.18.1}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid DeckCraft version: $version" >&2
  exit 1
fi
archive="deckcraft-web-${version}.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh release download "v${version}" --repo storytold/deckcraft --pattern "$archive" --pattern 'SHA256SUMS.txt' --dir "$tmp"
(
  cd "$tmp"
  # Require exactly one checksum for the downloaded archive.
  grep -E "^[[:xdigit:]]{64}  ${archive//./\.}$" SHA256SUMS.txt > web.sha256
  [[ $(wc -l < web.sha256) -eq 1 ]]
  sha256sum --check web.sha256
  unzip -q "$archive" -d unpacked
)
site="$tmp/unpacked/deckcraft-web-${version}"
test -f "$site/index.html"
mkdir -p _site
cp -a "$site/." _site/
touch _site/.nojekyll
echo "Prepared DeckCraft v${version} for GitHub Pages."
