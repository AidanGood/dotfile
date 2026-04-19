#!/usr/bin/env bash
# scripts/link_dots.sh
# Symlinks every file in dots/ into $HOME.
# Idempotent: skips already-correct links, backs up real files.
# Sourced by install.sh — do not run directly.

link_dots() {
    log::header "Linking dotfiles"

    local dots_dir="${DOTFILES_DIR}/dots"

    if [[ ! -d "$dots_dir" ]]; then
        log::error "dots/ directory not found at: ${dots_dir}"
        exit 1
    fi

    local linked=0 skipped=0 backed_up=0

    # Use nullglob so the loop doesn't run if dots/ is empty
    shopt -s nullglob

    for src in "${dots_dir}"/.*; do
        local name
        name="$(basename "$src")"

        # Skip . and ..
        [[ "$name" == "." || "$name" == ".." ]] && continue

        local target="${HOME}/${name}"

        # Already a symlink pointing to the right place — skip
        if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
            log::info "Already linked: ${name}"
            (( skipped++ )) || true
            continue
        fi

        # Real file or wrong symlink exists — back it up
        if [[ -e "$target" || -L "$target" ]]; then
            local backup="${target}.bak"
            # Avoid clobbering an existing backup
            if [[ -e "$backup" ]]; then
                backup="${target}.bak.$(date +%s)"
            fi
            mv "$target" "$backup"
            log::warn "Backed up existing ${name} → $(basename "$backup")"
            (( backed_up++ )) || true
        fi

        ln -sf "$src" "$target"
        log::ok "Linked: ${name}"
        (( linked++ )) || true
    done

    shopt -u nullglob

    log::info "Dotfiles: ${linked} linked, ${skipped} already up-to-date, ${backed_up} backed up"
}
