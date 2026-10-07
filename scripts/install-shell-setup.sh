#!/usr/bin/env bash
# Add the group shell setup to your ~/.bashrc (re-running replaces the block and keeps the options you enabled; shows what it changes).
# Also creates ~/.bash_profile (sourcing ~/.bashrc) if no login-shell file exists.
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

# Options a member enables by uncommenting a line in the block; kept across re-runs.
toggles=(
    "HPC_WRAP_LS=1|wrap 'ls -l' to show handles"
    "BENDALLGRP_LOAD_CONDA=1|load miniforge3 module and activate base"
)
old_block=""

if [[ -f "$bashrc" ]] && grep -qF "$begin" "$bashrc"; then
    grep -qF "$end" "$bashrc" || die "found '$begin' but no matching end marker in $bashrc; fix it by hand"
    old_block="$(sed -n "\|$begin|,\|$end|p" "$bashrc")"
    info "replacing the existing block in $bashrc (previous copy: $bashrc.bak)"
    if [[ "$DRY_RUN" != 1 ]]; then
        cp "$bashrc" "$bashrc.bak"
        tmp="$(mktemp)"
        sed "\|$begin|,\|$end|d" "$bashrc" > "$tmp" && cat "$tmp" > "$bashrc"
        rm -f "$tmp"
    fi
fi

block="$begin"
for t in "${toggles[@]}"; do
    assign="${t%%|*}"; note="${t#*|}"
    if grep -qE "^export ${assign%%=*}=" <<<"$old_block"; then
        prefix=""                  # the member enabled it; keep it enabled
    else
        prefix="# "
    fi
    block+=$'\n'"$(printf '%sexport %-24s # %s' "$prefix" "$assign" "$note")"
done
block+="
[ -r \"$setup\" ] && . \"$setup\"
$end"

if [[ "$DRY_RUN" == 1 ]]; then
    printf '[dry-run] append to %s:\n%s\n' "$bashrc" "$block"
else
    printf '\n%s\n' "$block" >> "$bashrc"
    info "added to $bashrc; run 'source $bashrc' or log in again"
fi

# Login shells read the first of .bash_profile, .bash_login, .profile and not .bashrc, so make
# sure that file sources .bashrc. Create .bash_profile if there is none; otherwise only warn.
profile_dir="$(dirname "$bashrc")"
profile=""
for f in .bash_profile .bash_login .profile; do
    if [[ -f "$profile_dir/$f" ]]; then profile="$profile_dir/$f"; break; fi
done
profile_snippet='if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi'
if [[ -z "$profile" ]]; then
    if [[ "$DRY_RUN" == 1 ]]; then
        printf '[dry-run] create %s:\n%s\n' "$profile_dir/.bash_profile" "$profile_snippet"
    else
        printf '%s\n' "$profile_snippet" > "$profile_dir/.bash_profile"
        info "created $profile_dir/.bash_profile so login shells read $bashrc"
    fi
elif ! grep -q 'bashrc' "$profile"; then
    warn "$profile does not mention .bashrc, so login shells may skip the group setup; add:"
    printf '%s\n' "$profile_snippet" >&2
fi
