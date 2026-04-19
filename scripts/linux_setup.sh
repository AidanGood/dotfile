#!/usr/bin/env bash
# scripts/linux_setup.sh
# Linux-specific configuration after package installation.
# Sourced by install.sh — do not run directly.

linux_setup() {
    log::header "Linux setup"

    _linux_set_bash_default
    _linux_fd_alias
}

# ── Default shell → bash ──────────────────────────────────────────────────────

_linux_set_bash_default() {
    local bash_path
    bash_path="$(command -v bash)"

    if [[ "$SHELL" == "$bash_path" ]]; then
        log::info "Default shell already set to ${bash_path}"
        return
    fi

    log::info "Changing default shell to ${bash_path} (requires password)"
    chsh -s "$bash_path"
    log::ok "Default shell changed to ${bash_path} — takes effect on next login"
}

# ── fd alias ─────────────────────────────────────────────────────────────────
# On apt, fd-find installs as 'fdfind'. Create a ~/.local/bin/fd alias
# so it behaves like the brew version.

_linux_fd_alias() {
    if ! command_exists fdfind; then
        log::info "fdfind not found — skipping fd alias"
        return
    fi

    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"

    local fd_link="${bin_dir}/fd"
    if [[ -L "$fd_link" && "$(readlink "$fd_link")" == "$(command -v fdfind)" ]]; then
        log::info "fd alias already in place"
        return
    fi

    ln -sf "$(command -v fdfind)" "$fd_link"
    log::ok "Created fd → fdfind alias in ${bin_dir}"
}
