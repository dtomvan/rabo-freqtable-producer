#!/usr/bin/env -S bash -eu
set -o pipefail

say() {
    printf "INFO: %s\n" "$@" 1>&2
}

yell() {
    printf "ERR: %s\n" "$@" 1>&2
}

die() {
    yell "$@"
    exit 1
}

exist() {
    if ! [ -f "$1" ]; then
        die "No such file or directory $1"
    fi
}

if [ "$1" = "--usage" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    die "Usage: $0 <source> <replay> [output]"
fi

if [ $# -lt 2 ]; then
    die "Expected at least 2 arguments, got $#"
fi

exist "$1"
exist "$2"

file -b "$2" | grep '^a vd -p script' >/dev/null || die "$2 is not a visidata script"

say "Performing $2 on $1..."
set -x

tmp="$(mktemp /tmp/XXXXXXXXX.vdj)"
source_file="$1"
sheet_name="$(basename $source_file)"
sheet_name="${sheet_name%.*}"
replay_file="$2"

cleanup() {
    set +x
    yell "vd failed, performing cleanup"
    say "generated file at $tmp:"
    cat "$tmp"
}

cp "$replay_file" "$tmp"
sed -i "$tmp" \
    -e "s|__SHEET__|$sheet_name|g" \
    -e "s|__FILENAME__|$source_file|g"

if [ "${VISIDATA_BATCH:-0}" = "1" ]; then
    kwargs=(-b)
fi

echo "$@"
vd -p "$tmp" "${kwargs[@]}" -o "${3:--}" "$source_file" "${@:4}" || cleanup
rm "$tmp"
