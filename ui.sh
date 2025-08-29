#!/usr/bin/env bash

# Colors (respect NO_COLOR and --color flag)
if [[ -n "${NO_COLOR:-}" ]]; then
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
else
    RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"
    BOLD="\e[1m"; RESET="\e[0m"
fi

log()   { echo -e "${BLUE}[sspm]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[warn]${RESET} $*" >&2; }
error() { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }
ok()    { echo -e "${GREEN}[ok]${RESET} $*"; }

spinner() {
    local pid=$1
    local msg="$2"
    local spin='-\|/'
    local i=0
    printf "%s " "$msg"
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r%s %s" "$msg" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r%s ${GREEN}done${RESET}\n" "$msg"
}
