#!/usr/bin/env bash

REPO_URL="${REPO_URL:-https://github.com/seuuser/seurepo.git}"
REPO_DIR="${REPO_DIR:-/var/lib/sspm/repo}"

sync_repo() {
    if [ -d "$REPO_DIR/.git" ]; then
        log "Updating repo in $REPO_DIR"
        (cd "$REPO_DIR" && git pull) || error "Failed to sync repo"
    else
        log "Cloning repo into $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR" || error "Failed to clone repo"
    fi
    ok "Repo synchronized"
}

find_recipe() {
    local name="$1"
    find "$REPO_DIR" -type f -name "$name-*.pkg" | sort -V | tail -n1
}
