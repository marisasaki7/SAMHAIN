#!/bin/bash
# Canonical Python-interpreter resolver -> $PY.
# - the ONE copy: sourced by the bundle scripts here (setup/run/package) and by
#   scripts/run/emscripten_tests.sh, so nothing drifts
# - must live in this dir: the export bundle is self-contained (90_package_emscripten.cmake copies
#   it) and its scripts source `$(dirname "$0")/_python.sh`
# - use:  . "$(dirname "$0")/_python.sh"  then call "$PY"
# - picks the first interpreter that ACTUALLY runs, not merely one on PATH: Windows' `python3`
#   App-Execution-Alias stub resolves on PATH but errors at runtime, so probe --version and fall
#   through to a real one
PY=""
for _py_cand in python3 python py; do
	if command -v "$_py_cand" >/dev/null 2>&1 && "$_py_cand" --version >/dev/null 2>&1; then
		PY="$_py_cand"
		break
	fi
done
[ -n "$PY" ] || { echo "error: no working python found on PATH (tried python3, python, py)" >&2; exit 1; }
