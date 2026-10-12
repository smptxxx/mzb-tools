#!/bin/bash
set -e

BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CORE="$BASE_DIR/mzb-tools-core.sh"

if [[ ! -x "$CORE" ]]; then
    printf 'mzb-tools-core.sh tidak ditemukan atau tidak executable\n' >&2
    exit 1
fi

export MZB_COMMAND="$(basename -- "$0")"
exec bash "$CORE" "$@"
