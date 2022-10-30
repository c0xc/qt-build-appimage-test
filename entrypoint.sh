#!/usr/bin/env bash
set -e
set -o pipefail
echo ">>> TEST"
echo ""
env
echo "entry test... $*"
#bash -c "set -e;  set -o pipefail; $1"
