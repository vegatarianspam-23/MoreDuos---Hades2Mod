#!/usr/bin/env bash
# Rebuilds the boon-icon atlas in data/ from art/icons/. Run after changing any icon, then commit data/.
# deps: python -m pip install --user deppth2

set -euo pipefail

GUID='SWu-MoreDuosMod'
PACKAGE="${GUID}BoonIcons"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$here/art/icons"
out="$here/data/$GUID"

export PATH="$PATH:$HOME/AppData/Roaming/Python/Python314/Scripts"
command -v deppth2.exe >/dev/null || { echo "deppth2 not found; python -m pip install --user deppth2" >&2; exit 1; }
[ -d "$src" ] || { echo "no art at $src" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp -r "$src" "$work/Icons"
mkdir -p "$out"

cd "$work"
mkdir -p out
deppth2.exe hpk -s Icons -t "$PACKAGE" -c BC7 >/dev/null
deppth2.exe pk -s "$PACKAGE" -t "out/$PACKAGE.pkg" -c BC7 >/dev/null

cp "$work/out/$PACKAGE.pkg" "$work/out/$PACKAGE.pkg_manifest" "$out/"

echo "built $PACKAGE -> data/$GUID/"
echo "textures are addressed as: $PACKAGE\\\\<name>"
