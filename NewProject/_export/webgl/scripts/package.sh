#!/bin/bash
# Assumption: execution at main level
# sh ./scripts/package.sh
#
# note: !/bin/bash -e doesn't seem to work
#--------------------------------------------------------------
set -e

# Resolve python3/python into $PY (no single name exists on all platforms) -- see _python.sh.
. "$(dirname "$0")/_python.sh"

# Resolve the emscripten tools dir (file_packager.py lives in <emscripten>/tools):
# - prefer $EMSCRIPTEN (CI exports it; points at .../upstream/emscripten)
# - else emcc on PATH -> its own dir is the emscripten root
# - else the pasted emsdk root in emsdk_directory.txt (<emsdk>/upstream/emscripten)
# The old code only honoured emsdk_directory.txt, whose committed value is one machine's path -- so
# package.sh could not run on CI or any other box.
if [ -n "${EMSCRIPTEN:-}" ]; then
	emscripten_path="$EMSCRIPTEN"
elif command -v emcc >/dev/null 2>&1; then
	emscripten_path="$(dirname "$(command -v emcc)")"
else
	emscripten_path="$(head -n 1 "$(dirname "$0")/emsdk_directory.txt")/upstream/emscripten"
fi
file_packager="$emscripten_path/tools/file_packager.py"

if [ ! -f "$file_packager" ]; then
	echo "ERROR: package.sh: file_packager.py not found at '$file_packager'."
	echo "  Set \$EMSCRIPTEN to <emsdk>/upstream/emscripten, put emcc on PATH, or paste the emsdk root"
	echo "  into $(dirname "$0")/emsdk_directory.txt (see setup_emscripten.sh)."
	exit 1
fi
echo "file_packager: $file_packager"

cd ./data

# Start clean: a previous run leaves project.data/loader.js in ./, and --preload ./ would fold them
# straight back into the new bundle -- doubling its size every run. Delete them before packaging.
rm -f project.data loader.js

# Create timestamp to make sure we can confirm project.data is current
# (in ex. Developer Tools)
timestamp=$(date +%F_%T)
echo $timestamp > "packaged_at.txt"

# Run packager
"$PY" "$file_packager" project.data --js-output=loader.js --preload ./

# Note: need to manually copy these back to top-level directory due to
# file_packager.py creating invalid loader.js configuration when passing relative values

cp project.data ../project.data
cp loader.js ../loader.js
