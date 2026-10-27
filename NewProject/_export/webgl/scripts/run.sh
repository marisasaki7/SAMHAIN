#!/bin/bash
# Assumption: execution at main level
# sh ./scripts/run.sh
#
# note: !/bin/bash -e doesn't seem to work
#--------------------------------------------------------------
set -e

# Resolve python3/python into $PY (no single name exists on all platforms) -- see _python.sh.
. "$(dirname "$0")/_python.sh"
"$PY" --version

pushd .
source ./scripts/package.sh
popd
echo ""

# run server
"$PY" ./scripts/server.py --open
