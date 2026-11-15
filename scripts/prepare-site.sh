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
# Enumerate each app's static files for optional, complete offline downloads.
python3 - "$tmp/site" scripts/releases.tsv <<'PYTHON'
import json, sys
from pathlib import Path
from urllib.parse import quote
root = Path(sys.argv[1])
manifest = {}
for line in Path(sys.argv[2]).read_text().splitlines():
    if not line.strip() or line.lstrip().startswith('#'):
        continue
    repo, _, version = line.split()
    files = sorted(p for p in (root / repo).rglob('*') if p.is_file() and not any(part.startswith('.') for part in p.relative_to(root).parts))
    manifest[repo] = {'version': version, 'files': ['/'.join(quote(part, safe='') for part in p.relative_to(root).parts) for p in files]}
(root / 'offline-apps.json').write_text(json.dumps(manifest, separators=(',', ':')))
PYTHON
# Only replace the prior output after every app has been verified and assembled.
rm -rf _site
mv "$tmp/site" _site
echo 'Prepared all releases for GitHub Pages.'
