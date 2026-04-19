#!/usr/bin/env bash
# lib/utils.sh — shared utility helpers
# Assumes OS and BREW_PREFIX are set by bootstrap.sh

command_exists() {
    command -v "$1" &>/dev/null
}

is_macos() {
    [[ "${OS:-}" == "macos" ]]
}

is_linux() {
    [[ "${OS:-}" == "linux" ]]
}

is_arm() {
    [[ "$(uname -m)" == "arm64" ]]
}

get_brew_prefix() {
    if is_arm; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# require <cmd> [message]
# Exits with an error if the command is not found.
require() {
    local cmd="$1"
    local msg="${2:-Required command \"$cmd\" not found. Please install it and re-run.}"
    if ! command_exists "$cmd"; then
        log::error "$msg"
        exit 1
    fi
}

# read_pkg_file <path>
# Prints non-empty, non-comment lines from a package file.
read_pkg_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log::error "Package file not found: $file"
        exit 1
    fi
    grep -v '^\s*#' "$file" | grep -v '^\s*$' | awk '{print $1}'
}
