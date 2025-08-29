#!/usr/bin/env bash

resolve_deps() {
    dir="$1"; shift
    reverse=false
    if [[ "${1:-}" == "--reverse" ]]; then
        reverse=true
    fi

    pkgs=($(find "$dir" -type f -name "*.pkg"))
    ordered=($(toposort "${pkgs[@]}"))

    if $reverse; then
        for ((i=${#ordered[@]}-1; i>=0; i--)); do
            echo "${ordered[$i]}"
        done
    else
        printf "%s\n" "${ordered[@]}"
    fi
}

toposort() {
    declare -A deps
    declare -A visited
    declare -a result

    for r in "$@"; do
        . "$r"
        deps["$pkgname"]="${depends[*]:-}"
        files["$pkgname"]="$r"
    done

    dfs() {
        local n=$1
        [[ ${visited[$n]} == 1 ]] && return
        visited[$n]=1
        for d in ${deps[$n]}; do
            dfs "$d"
        done
        result+=("${files[$n]}")
    }

    for r in "$@"; do
        . "$r"
        dfs "$pkgname"
    done

    printf "%s\n" "${result[@]}"
}

list_orphans() {
    log "Checking for orphans..."
    for f in "$PKGDB"/*; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        deps="$(grep depends= "$(cat "$f")" || true)"
        if [ -z "$deps" ]; then
            echo "$name"
        fi
    done
}
