#!/usr/bin/env bash

set -eu

target=$1
make_command=$2

case "$target" in
    ../../../*/output/*)
        tasks_root=../../..
        relative=${target#../../../}
        ;;
    ../../*/output/*)
        tasks_root=../..
        relative=${target#../../}
        ;;
    *)
        exit 0
        ;;
esac

task=${relative%%/output/*}
output=../output/${relative#*/output/}

if [ -z "${LIHTC_UPSTREAM_STATUS_CACHE:-}" ]; then
    LIHTC_UPSTREAM_STATUS_CACHE=$(mktemp -d "${TMPDIR:-/tmp}/lihtc-upstream-status.XXXXXX")
    export LIHTC_UPSTREAM_STATUS_CACHE
    trap 'rm -rf "$LIHTC_UPSTREAM_STATUS_CACHE"' EXIT
    trap 'exit 1' HUP INT TERM
fi

absolute_target=$(cd "$tasks_root" && pwd -P)/$relative
cache_file=$LIHTC_UPSTREAM_STATUS_CACHE$absolute_target.status
mkdir -p "$(dirname "$cache_file")"

if [ -f "$cache_file" ]; then
    IFS= read -r status < "$cache_file"
else
    printf 'checking\n' > "$cache_file"
    if MAKEFLAGS= "$make_command" -q -C "$tasks_root/$task/code" "$output" >/dev/null 2>&1; then
        status=current
    else
        status=stale
    fi
    printf '%s\n' "$status" > "$cache_file"
fi

if [ "$status" != current ]; then
    printf 'FORCE_UPSTREAM'
fi
