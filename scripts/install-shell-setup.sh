#!/usr/bin/env bash
# Add the group shell setup to your ~/.bashrc (idempotent; shows what it changes).
#
# Usage: install-shell-setup.sh [-n|--dry-run] [--bashrc FILE]
set -euo pipefail
# Resolve symlinks so the script works when run via local/bin/ (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

bashrc="$HOME/.bashrc"
args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bashrc) bashrc="${2:?--bashrc needs a file}"; shift ;;
        *) args+=("$1") ;;
    esac
    shift
done
parse_common_flags "${args[@]+"${args[@]}"}"

setup="$LOCAL_ROOT/etc/group-bashrc.sh"     # stable path, a symlink into the repo (see link-local.sh)
[[ -r "$setup" || "$DRY_RUN" == 1 ]] || die "$setup not found; the admin must run scripts/link-local.sh first"
begin="# >>> bendallgrp shell setup >>>"
end="# <<< bendallgrp shell setup <<<"

if [[ -f "$bashrc" ]] && grep -qF "$begin" "$bashrc"; then
    info "already installed in $bashrc"
    exit 0
fi

block="$begin
[ -r \"$setup\" ] && . \"$setup\"
$end"

if [[ "$DRY_RUN" == 1 ]]; then
    printf '[dry-run] append to %s:\n%s\n' "$bashrc" "$block"
else
    printf '\n%s\n' "$block" >> "$bashrc"
    info "added to $bashrc; run 'source $bashrc' or log in again"
fi
