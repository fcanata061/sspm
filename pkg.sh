#!/usr/bin/env bash

list_packages() {
    ls "$PKGDB"
}

show_info() {
    name="$1"
    [ -f "$PKGDB/$name" ] || error "Not installed: $name"
    echo "Package: $name"
    echo "Source: $(cat "$PKGDB/$name")"
}
