#!/usr/bin/env bash
# scripts/bootstrap.sh
# Sets OS, BREW_PREFIX, validates dependencies.
# Sourced by install.sh — do not run directly.

bootstrap() {
    log::header "Bootstrap"

    _detect_os
    _detect_arch
    _check_bash_version
    _check_deps

    log::ok "Bootstrap complete (OS=${OS}, BREW_PREFIX=${BREW_PREFIX:-n/a})"
}

_detect_os() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux)  OS="linux" ;;
        *)
            log::error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
    export OS
    log::info "Detected OS: ${OS}"
}

_detect_arch() {
    ARCH="$(uname -m)"
    export ARCH

    if is_macos; then
        BREW_PREFIX="$(get_brew_prefix)"
        export BREW_PREFIX
        log::info "Detected arch: ${ARCH}, Homebrew prefix: ${BREW_PREFIX}"
    fi
}

_check_bash_version() {
    local major="${BASH_VERSINFO[0]}"
    if [[ "$major" -lt 4 ]]; then
        log::warn "Bash ${BASH_VERSION} detected — this script requires bash 4+."
        if is_macos; then
            log::warn "Install a newer bash with: brew install bash"
            log::warn "Then re-run with: ${BREW_PREFIX}/bin/bash install.sh"
        fi
        exit 1
    fi
    log::info "Bash version: ${BASH_VERSION}"
}

_check_deps() {
    local deps=(git curl)
    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            log::info "Found: ${dep}"
        else
            log::error "Missing required dependency: ${dep}"
            exit 1
        fi
    done
}
