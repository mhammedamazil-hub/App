#!/usr/bin/env bash
# Assemble the Pages site from pinned, checksum-verified upstream releases.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/site"
cp -a site/. "$tmp/site/"
touch "$tmp/site/.nojekyll"
while read -r repo prefix version extra; do
  [[ -z "$repo" || "$repo" == \#* ]] && continue
  [[ "$repo" =~ ^[a-z0-9-]+$ && "$prefix" =~ ^[a-z0-9-]+$ && "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && -z "${extra:-}" ]] || { echo "Invalid release entry: $repo $prefix $version ${extra:-}" >&2; exit 1; }
  archive="${prefix}-web-${version}.zip"
  work="$tmp/download/$repo"
  mkdir -p "$work"
  echo "Downloading $repo v$version"
  gh release download "v${version}" --repo "storytold/$repo" --pattern "$archive" --pattern SHA256SUMS.txt --dir "$work"
  (
    cd "$work"
    # Require exactly one checksum entry for this exact filename.
    awk -v name="$archive" '$2 == name || $2 == "*" name {print}' SHA256SUMS.txt > web.sha256
    [[ $(wc -l < web.sha256) -eq 1 ]]
    sha256sum --check web.sha256
    unzip -q "$archive" -d unpacked
  )
  source_dir="$work/unpacked/${prefix}-web-${version}"
  test -f "$source_dir/index.html" || { echo "Missing index.html in $archive" >&2; exit 1; }
  mkdir -p "$tmp/site/$repo"
  cp -a "$source_dir/." "$tmp/site/$repo/"
done < scripts/releases.tsv
# Only replace the prior output after every app has been verified and assembled.
rm -rf _site
mv "$tmp/site" _site
echo 'Prepared all releases for GitHub Pages.'
