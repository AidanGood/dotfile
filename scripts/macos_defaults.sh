#!/usr/bin/env bash
# scripts/macos_defaults.sh
# Applies macOS system preferences from packages/macos_defaults.tsv.
# Idempotent: reads current value, only writes on mismatch, only restarts
# affected apps if something actually changed.
# Sourced by install.sh — do not run directly.

apply_macos_defaults() {
    log::header "Applying macOS defaults"

    NEEDS_DOCK_RESTART=0
    NEEDS_FINDER_RESTART=0
    NEEDS_SYSTEMUI_RESTART=0

    _macos_apply_tsv
    _macos_keyboard_shortcuts
    _macos_set_bash_default
    _macos_restart_affected_apps
}

# ── Menu-item keyboard shortcuts ──────────────────────────────────────────────
# NSUserKeyEquivalents lets you override menu-item shortcuts per app (or
# globally via NSGlobalDomain). Modifiers: @=Cmd, ~=Option, $=Shift, ^=Ctrl.
# The menu item name must match exactly — including unicode ellipsis (…).
# Takes effect the next time the target app launches.

_macos_keyboard_shortcuts() {
    log::info "Keyboard shortcuts"
    # Cmd+L → Sleep (global)
    _set_menu_shortcut NSGlobalDomain    "Sleep"           "@l"
    # Free Cmd+L in Safari (default: Open Location…) by moving it to Cmd+Opt+L
    _set_menu_shortcut com.apple.Safari  "Open Location…"  "@~l"
}

# _set_menu_shortcut <domain> <menu-item> <shortcut>
# Idempotent at the data level — -dict-add is set-or-update.
_set_menu_shortcut() {
    local domain="$1" menu="$2" shortcut="$3"

    # Check existing binding. Unicode chars in keys get escaped (e.g. … → \U2026),
    # so we probe via PlistBuddy on the preferences plist for an exact match.
    local plist="${HOME}/Library/Preferences/${domain}.plist"
    [[ "$domain" == "NSGlobalDomain" ]] && plist="${HOME}/Library/Preferences/.GlobalPreferences.plist"

    local current
    current="$(/usr/libexec/PlistBuddy -c "Print :NSUserKeyEquivalents:${menu}" "$plist" 2>/dev/null || echo "__unset__")"

    if [[ "$current" == "$shortcut" ]]; then
        log::info "Already bound: ${domain} '${menu}' → ${shortcut}"
        return
    fi

    defaults write "$domain" NSUserKeyEquivalents -dict-add "$menu" "$shortcut"
    log::ok "Bound: ${domain} '${menu}' → ${shortcut}  (was: ${current})"
}

# Normalize a bool to "true"/"false" regardless of the form macOS returned.
_normalize_bool() {
    case "$1" in
        1|true|YES)  echo "true"  ;;
        0|false|NO)  echo "false" ;;
        *)           echo "$1"    ;;
    esac
}

# set_default <domain> <key> <type> <value> <restart_token>
set_default() {
    local domain="$1" key="$2" type="$3" value="$4" restart="${5:-}"

    # Expand $HOME in the value (TSV stores paths as $HOME/...)
    value="${value//\$HOME/$HOME}"

    local current
    current="$(defaults read "$domain" "$key" 2>/dev/null || echo "__unset__")"

    local current_cmp="$current" value_cmp="$value"
    if [[ "$type" == "bool" ]]; then
        current_cmp="$(_normalize_bool "$current")"
        value_cmp="$(_normalize_bool "$value")"
    fi

    if [[ "$current_cmp" == "$value_cmp" ]]; then
        log::info "Already set: ${key} = ${value}"
        return
    fi

    defaults write "$domain" "$key" "-${type}" "$value"
    log::ok "Set: ${key} = ${value}  (was: ${current})"

    case "$restart" in
        dock)     NEEDS_DOCK_RESTART=1 ;;
        finder)   NEEDS_FINDER_RESTART=1 ;;
        systemui) NEEDS_SYSTEMUI_RESTART=1 ;;
    esac
}

_macos_apply_tsv() {
    local tsv="${DOTFILES_DIR}/packages/macos_defaults.tsv"

    if [[ ! -f "$tsv" ]]; then
        log::error "Missing snapshot file: ${tsv}"
        return 1
    fi

    local line domain key type value restart
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip blanks and comments
        [[ -z "${line// }" || "${line:0:1}" == "#" ]] && continue

        IFS=$'\t' read -r domain key type value restart <<< "$line"

        if [[ -z "$domain" || -z "$key" || -z "$type" ]]; then
            log::warn "Malformed TSV line: ${line}"
            continue
        fi

        set_default "$domain" "$key" "$type" "$value" "$restart"
    done < "$tsv"
}

# ── Default shell → Homebrew bash ─────────────────────────────────────────────
# Not a `defaults write` — kept as a dedicated step.

_macos_set_bash_default() {
    log::info "Default shell"

    local brew_bash="${BREW_PREFIX}/bin/bash"

    if [[ ! -f "$brew_bash" ]]; then
        log::warn "Homebrew bash not found at ${brew_bash} — skipping chsh"
        log::warn "Install it with: brew install bash"
        return
    fi

    if ! grep -qF "$brew_bash" /etc/shells; then
        log::info "Adding ${brew_bash} to /etc/shells (requires sudo)"
        echo "$brew_bash" | sudo tee -a /etc/shells > /dev/null
        log::ok "Added ${brew_bash} to /etc/shells"
    fi

    if [[ "$SHELL" == "$brew_bash" ]]; then
        log::info "Default shell already set to ${brew_bash}"
        return
    fi

    log::info "Changing default shell to ${brew_bash} (requires password)"
    chsh -s "$brew_bash"
    log::ok "Default shell changed to ${brew_bash} — takes effect on next login"
}

# ── Restart affected apps ─────────────────────────────────────────────────────

_macos_restart_affected_apps() {
    if [[ "$NEEDS_DOCK_RESTART" -eq 1 ]]; then
        killall Dock 2>/dev/null || true
        log::info "Restarted Dock"
    fi
    if [[ "$NEEDS_FINDER_RESTART" -eq 1 ]]; then
        killall Finder 2>/dev/null || true
        log::info "Restarted Finder"
    fi
    if [[ "$NEEDS_SYSTEMUI_RESTART" -eq 1 ]]; then
        killall SystemUIServer 2>/dev/null || true
        log::info "Restarted SystemUIServer"
    fi
}
