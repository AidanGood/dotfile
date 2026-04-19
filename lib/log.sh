#!/usr/bin/env bash
# lib/log.sh — shared logging helpers
# Respects VERBOSE env var (default: 1)
# log::ok and log::error always print regardless of VERBOSE

log::header() {
    printf "\n\033[1m==> %s\033[0m\n" "$*"
}

log::info() {
    [[ ${VERBOSE:-1} -ge 1 ]] && printf "  \033[34m•\033[0m %s\n" "$*"
    return 0
}

log::ok() {
    printf "  \033[32m✓\033[0m %s\n" "$*"
}

log::warn() {
    printf "  \033[33m⚠\033[0m %s\n" "$*" >&2
}

log::error() {
    printf "  \033[31m✗\033[0m %s\n" "$*" >&2
}
