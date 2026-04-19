#!/usr/bin/env bash
# scripts/bootstrap.sh
# Sets OS, BREW_PREFIX, validates dependencies.
# Sourced by install.sh — do not run directly.

bootstrap() {
    log::header "Bootstrap"

    _detect_os
    _detect_arch
    is_macos && _ensure_xcode_clt
    _check_deps
    _sudo_keepalive
    is_macos && _ensure_modern_bash
    _check_bash_version

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
        log::error "Bash ${BASH_VERSION} detected — this script requires bash 4+."
        exit 1
    fi
    log::info "Bash version: ${BASH_VERSION}"
}

# Stock macOS ships bash 3.2 (GPLv2-era). Rather than bail out and tell the
# user to reinstall, install Homebrew bash here and re-exec this installer
# under it. Guarded by DOTFILES_BASH_REEXEC to prevent loops.
_ensure_modern_bash() {
    [[ "${BASH_VERSINFO[0]}" -ge 4 ]] && return

    if [[ -n "${DOTFILES_BASH_REEXEC:-}" ]]; then
        log::error "Already re-exec'd but bash is still ${BASH_VERSION} — aborting"
        exit 1
    fi

    local brew_bash="${BREW_PREFIX}/bin/bash"

    if [[ ! -x "$brew_bash" ]]; then
        log::info "Old bash (${BASH_VERSION}) — bootstrapping Homebrew bash"
        _ensure_brew           # defined in install_packages.sh (sourced before bootstrap runs)
        log::info "Installing modern bash via brew"
        brew install bash --quiet
    fi

    log::ok "Re-executing installer under ${brew_bash}"
    export DOTFILES_BASH_REEXEC=1
    exec "$brew_bash" "${DOTFILES_DIR}/install.sh" "$@"
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

# On a fresh macOS, git/curl are stubs that trigger the Xcode CLT installer GUI.
# Kick off the install ourselves and block until it finishes, so the rest of
# the run has a working toolchain.
_ensure_xcode_clt() {
    if xcode-select -p &>/dev/null; then
        log::info "Xcode Command Line Tools present"
        return
    fi

    log::warn "Xcode Command Line Tools not installed — triggering installer"
    xcode-select --install &>/dev/null || true

    log::info "Waiting for Command Line Tools install to complete (accept the GUI prompt)..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    log::ok "Xcode Command Line Tools installed"
}

# Prime sudo once at the top of the run and keep the timestamp fresh in the
# background so later steps (editing /etc/shells, chsh, etc.) don't re-prompt.
# The keepalive dies automatically when this script exits.
_sudo_keepalive() {
    if ! sudo -n true 2>/dev/null; then
        log::info "Requesting sudo (cached for the rest of the run)"
        sudo -v || { log::error "sudo authentication failed"; exit 1; }
    fi

    (
        while kill -0 "$$" 2>/dev/null; do
            sudo -n -v 2>/dev/null || exit
            sleep 60
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
    export SUDO_KEEPALIVE_PID
    log::info "sudo keepalive running (pid ${SUDO_KEEPALIVE_PID})"
}
