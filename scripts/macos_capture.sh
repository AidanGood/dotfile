#!/usr/bin/env bash
# scripts/macos_capture.sh
# Reads the domain/key pairs listed in packages/macos_defaults.tsv and
# rewrites the value column with the current value on this machine.
# Run manually when you've tweaked System Settings and want to snapshot.
#
# Usage: ./scripts/macos_capture.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TSV="${DOTFILES_DIR}/packages/macos_defaults.tsv"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "macos_capture.sh only runs on macOS" >&2
    exit 1
fi

# Normalize a raw `defaults read` value into the TSV form we store.
# bool: 1→true, 0→false. Everything else: passthrough (trimmed).
_normalize() {
    local type="$1" raw="$2"
    case "$type" in
        bool)
            case "$raw" in
                1|true|YES)  echo "true"  ;;
                0|false|NO)  echo "false" ;;
                *)           echo "$raw"  ;;
            esac
            ;;
        *) echo "$raw" ;;
    esac
}

tmp="$(mktemp)"
updated=0 unchanged=0 missing=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # Preserve comments and blank lines verbatim
    if [[ -z "${line// }" || "${line:0:1}" == "#" ]]; then
        printf '%s\n' "$line" >> "$tmp"
        continue
    fi

    IFS=$'\t' read -r domain key type old_value restart <<< "$line"

    raw="$(defaults read "$domain" "$key" 2>/dev/null || echo "__unset__")"

    if [[ "$raw" == "__unset__" ]]; then
        echo "  missing: ${domain} ${key} (keeping old value '${old_value}')" >&2
        printf '%s\t%s\t%s\t%s\t%s\n' "$domain" "$key" "$type" "$old_value" "$restart" >> "$tmp"
        (( missing++ )) || true
        continue
    fi

    new_value="$(_normalize "$type" "$raw")"

    # Expand $HOME in the old value for fair comparison
    old_expanded="${old_value//\$HOME/$HOME}"
    if [[ "$new_value" == "$old_expanded" ]]; then
        (( unchanged++ )) || true
    else
        echo "  updated: ${key}  ${old_value} → ${new_value}" >&2
        (( updated++ )) || true
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$domain" "$key" "$type" "$new_value" "$restart" >> "$tmp"
done < "$TSV"

mv "$tmp" "$TSV"
echo "Snapshot written to ${TSV}" >&2
echo "  ${updated} updated, ${unchanged} unchanged, ${missing} missing" >&2
