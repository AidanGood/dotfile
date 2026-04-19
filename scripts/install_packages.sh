#!/usr/bin/env bash
# scripts/install_packages.sh
# Reads packages/brew.txt or packages/apt.txt and installs missing packages.
# Idempotent: checks if each package is already installed before acting.
# Sourced by install.sh — do not run directly.

install_packages() {
    log::header "Installing packages"

    if is_macos; then
        _ensure_brew
        _brew_install_all
    elif is_linux; then
        _detect_linux_pm
        _apt_install_all
    fi
}

# ── Homebrew ──────────────────────────────────────────────────────────────────

_ensure_brew() {
    if command_exists brew; then
        log::info "Homebrew already installed"
        return
    fi

    log::warn "Homebrew not found."
    read -r -p "  Install Homebrew now? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        log::info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for the rest of this session
        eval "$("${BREW_PREFIX}/bin/brew" shellenv)"
        log::ok "Homebrew installed"
    else
        log::error "Homebrew is required on macOS. Aborting."
        exit 1
    fi
}

_brew_install_all() {
    local pkg_file="${DOTFILES_DIR}/packages/brew.txt"
    local installed=0 skipped=0

    # Update once before installing
    log::info "Running brew update..."
    brew update --quiet

    while IFS= read -r pkg; do
        _brew_install_one "$pkg" && (( installed++ )) || (( skipped++ )) || true
    done < <(read_pkg_file "$pkg_file")

    log::info "Brew packages: ${installed} installed, ${skipped} already present"
}

_brew_install_one() {
    local pkg="$1"

    # Check if it's a cask
    local is_cask=0
    if [[ "$pkg" == --cask:* ]]; then
        pkg="${pkg#--cask:}"
        is_cask=1
    fi

    if [[ "$is_cask" -eq 1 ]]; then
        if brew list --cask "$pkg" &>/dev/null; then
            log::info "Already installed (cask): ${pkg}"
            return 1
        fi
        if brew install --cask "$pkg" --quiet; then
            log::ok "Installed (cask): ${pkg}"
            return 0
        else
            log::warn "Failed to install cask: ${pkg}"
            return 1
        fi
    else
        if brew list --formula "$pkg" &>/dev/null; then
            log::info "Already installed: ${pkg}"
            return 1
        fi
        if brew install "$pkg" --quiet; then
            log::ok "Installed: ${pkg}"
            return 0
        else
            log::warn "Failed to install: ${pkg}"
            return 1
        fi
    fi
}

# ── apt ───────────────────────────────────────────────────────────────────────

_detect_linux_pm() {
    if command_exists apt-get; then
        LINUX_PM="apt"
    else
        log::error "No supported package manager found (apt-get). Skipping package install."
        LINUX_PM="unsupported"
    fi
    export LINUX_PM
}

_apt_install_all() {
    if [[ "${LINUX_PM}" == "unsupported" ]]; then
        return
    fi

    local pkg_file="${DOTFILES_DIR}/packages/apt.txt"
    local installed=0 skipped=0

    log::info "Updating apt package list..."
    sudo apt-get update -qq

    while IFS= read -r pkg; do
        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            log::info "Already installed: ${pkg}"
            (( skipped++ )) || true
        else
            if sudo apt-get install -y -qq "$pkg"; then
                log::ok "Installed: ${pkg}"
                (( installed++ )) || true
            else
                log::warn "Failed to install: ${pkg}"
            fi
        fi
    done < <(read_pkg_file "$pkg_file")

    log::info "Apt packages: ${installed} installed, ${skipped} already present"
}
