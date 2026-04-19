#!/usr/bin/env bash
# scripts/verify.sh
# Confirms symlinks are in place and prints a final summary.
# Sourced by install.sh — do not run directly.

verify() {
    log::header "Verification"

    local dots_dir="${DOTFILES_DIR}/dots"
    local ok=0 broken=0

    shopt -s nullglob

    for src in "${dots_dir}"/.*; do
        local name
        name="$(basename "$src")"
        [[ "$name" == "." || "$name" == ".." ]] && continue

        local target="${HOME}/${name}"

        if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
            log::ok "${name} → ${src}"
            (( ok++ )) || true
        else
            log::warn "${name} — symlink missing or incorrect"
            (( broken++ )) || true
        fi
    done

    shopt -u nullglob

    printf "\n"
    if [[ "$broken" -eq 0 ]]; then
        log::ok "All ${ok} dotfiles correctly linked"
    else
        log::warn "${ok} linked, ${broken} missing — re-run install.sh to fix"
    fi

    printf "\n"
    log::ok "Done. Open a new shell to pick up all changes."
}
