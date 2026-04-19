#!/usr/bin/env bash
# scripts/verify.sh
# Confirms symlinks are in place and prints a final summary.
# Sourced by install.sh — do not run directly.

verify() {
    log::header "Verification"
    _verify_symlinks
    printf "\n"
    _verify_packages
    printf "\n"
    log::ok "Done. Open a new shell to pick up all changes."
}

_verify_symlinks() {
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

    if [[ "$broken" -eq 0 ]]; then
        log::ok "All ${ok} dotfiles correctly linked"
    else
        log::warn "${ok} linked, ${broken} missing — re-run install.sh to fix"
    fi
}

# _pkg_to_binary <pkg>
# Prints the binary name to look up on PATH for a package, or nothing if the
# package provides no CLI binary worth verifying (libraries, meta-packages,
# GUI casks, keg-only formulae).
_pkg_to_binary() {
    local pkg="$1"
    case "$pkg" in
        --cask:*)         return ;;                          # GUI apps
        ripgrep)          echo rg ;;
        fd-find)          echo fdfind ;;                     # linux_setup symlinks → fd
        sqlite|sqlite3)   echo sqlite3 ;;
        python3-pip)      echo pip3 ;;
        # apt's bat collides with another package and installs as batcat
        bat)              is_linux && echo batcat || echo bat ;;
        # No canonical binary on PATH — skip
        python3-venv|build-essential|llvm) ;;
        *)                echo "$pkg" ;;
    esac
}

_verify_packages() {
    local pkg_file
    if is_macos; then
        pkg_file="${DOTFILES_DIR}/packages/brew.txt"
    else
        pkg_file="${DOTFILES_DIR}/packages/apt.txt"
    fi

    local found=0 skipped=0
    local missing=()

    while IFS= read -r pkg; do
        local bin
        bin="$(_pkg_to_binary "$pkg")"

        if [[ -z "$bin" ]]; then
            (( skipped++ )) || true
            continue
        fi

        if command_exists "$bin"; then
            (( found++ )) || true
        else
            missing+=("${pkg} → ${bin}")
        fi
    done < <(read_pkg_file "$pkg_file")

    if (( ${#missing[@]} == 0 )); then
        log::ok "All ${found} package binaries on PATH (${skipped} skipped)"
    else
        log::warn "${found} on PATH, ${#missing[@]} missing (${skipped} skipped):"
        for m in "${missing[@]}"; do
            log::warn "  - ${m}"
        done
    fi
}
