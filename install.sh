#!/usr/bin/env bash
# install.sh — dotfiles setup entry point
#
# Usage:
#   ./install.sh            # normal install (VERBOSE=1)
#   VERBOSE=0 ./install.sh  # quiet — only warnings, errors, and summary

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR
export VERBOSE="${VERBOSE:-1}"

# ── Source shared libraries ───────────────────────────────────────────────────
source "${DOTFILES_DIR}/lib/log.sh"
source "${DOTFILES_DIR}/lib/utils.sh"

# ── Source modules (loads functions, does not run them yet) ───────────────────
source "${DOTFILES_DIR}/scripts/bootstrap.sh"
source "${DOTFILES_DIR}/scripts/link_dots.sh"
source "${DOTFILES_DIR}/scripts/install_packages.sh"
source "${DOTFILES_DIR}/scripts/macos_defaults.sh"
source "${DOTFILES_DIR}/scripts/linux_setup.sh"
source "${DOTFILES_DIR}/scripts/verify.sh"

# ── Run ───────────────────────────────────────────────────────────────────────
bootstrap
link_dots
install_packages

if is_macos; then
    apply_macos_defaults
    source "${DOTFILES_DIR}/packages/post_install_macos.sh"
else
    linux_setup
    source "${DOTFILES_DIR}/packages/post_install_linux.sh"
fi

verify
