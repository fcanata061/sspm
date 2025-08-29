#!/usr/bin/env bash

PKGDB="/var/lib/sspm"
mkdir -p "$PKGDB"

build_pkgs() {
    dir="$1"
    [ -d "$dir" ] || error "No recipe dir: $dir"

    pkgs=($(find "$dir" -type f -name "*.pkg"))
    [ ${#pkgs[@]} -gt 0 ] || error "No recipes found in $dir"

    ordered=($(toposort "${pkgs[@]}"))

    for recipe in "${ordered[@]}"; do
        build_pkg "$recipe"
    done
}

build_pkg() {
    recipe="$1"
    . "$recipe"

    srcdir="$(pwd)/src/$pkgname-$pkgver"
    pkgdir="$(pwd)/pkg/$pkgname-$pkgver"

    rm -rf "$srcdir" "$pkgdir"
    mkdir -p "$srcdir" "$pkgdir"

    log "Fetching sources for $pkgname..."
    for url in "${source[@]}"; do
        file="$(basename "$url")"
        [ -f "$file" ] || curl -sLO "$url"
        cp "$file" "$srcdir/"
    done

    cd "$srcdir"/*

    [ "$(type -t prepare)" = function ] && prepare
    [ "$(type -t build)" = function ] && build
    [ "$(type -t check)" = function ] && check
    [ "$(type -t package)" = function ] && package

    pkgfile="${pkgname}-${pkgver}-${pkgrel}.tar.zst"
    log "Packaging $pkgfile"
    ( tar -C "$pkgdir" -cf - . | zstd -z -o "$pkgfile" ) &
    spinner $! "Compressing"

    ok "Built package: $pkgfile"
}

install_pkg() {
    pkgfile="$1"
    [ -f "$pkgfile" ] || error "Package not found: $pkgfile"

    log "Installing $pkgfile"
    tmpdir=$(mktemp -d)
    tar -I zstd -C "$tmpdir" -xf "$pkgfile"

    cp -a "$tmpdir"/* /
    name="$(basename "$pkgfile" .tar.zst)"
    manifest="$PKGDB/$name.files"
    (cd "$tmpdir" && find . -type f) > "$manifest"
    echo "$pkgfile" > "$PKGDB/$name"
    rm -rf "$tmpdir"

    [ "$(type -t post_install)" = function ] && post_install
    ok "Installed $name"
}

remove_pkg() {
    name="$1"
    [ -f "$PKGDB/$name" ] || error "Not installed: $name"

    log "Removing $name"
    manifest="$PKGDB/$name.files"
    if [ -f "$manifest" ]; then
        while read -r f; do
            rm -f "/$f"
        done < "$manifest"
        rm -f "$manifest"
    fi
    rm -f "$PKGDB/$name"

    [ "$(type -t post_remove)" = function ] && post_remove
    ok "Removed $name"
}

upgrade_pkgs() {
    log "Checking for upgrades..."
    for meta in "$PKGDB"/*; do
        [ -f "$meta" ] || continue
        name="$(basename "$meta")"
        oldver=$(cut -d- -f2 <<<"$name")
        recipe=$(find_recipe "$name" | sed 's#.*/##')
        [ -n "$recipe" ] || continue

        . "$REPO_DIR"/*/"$recipe"
        newver="$pkgver"

        if [ "$newver" \> "$oldver" ]; then
            log "Upgrading $name -> $pkgname-$newver"
            resolve_and_install "$pkgname"
        fi
    done
    ok "Upgrade check finished"
}
