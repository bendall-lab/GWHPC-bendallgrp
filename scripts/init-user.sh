#!/usr/bin/env bash
# Create a member's personal directories on NFS and scratch, named by their handle,
# plus a dot-symlink named after the Linux username:
#   users/<handle>/            (real directory)
#   users/.<linux_user>  ->  <handle>
# The handle comes from the user map (scripts/user-map.sh add ... first).
#
# Usage: init-user.sh [-n|--dry-run] [LINUX_USER]     (default: $USER)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
parse_common_flags "$@"

linux_user="${REST_ARGS[0]:-$USER}"
handle="$(map_handle_for "$linux_user" || true)"
[[ -n "$handle" ]] || die "no handle for $linux_user in $USER_MAP; run: scripts/user-map.sh add $linux_user HANDLE"

for root in "$GROUP_ROOT/users" "$SCRATCH_ROOT/users"; do
    make_dir "$root/$handle" 2775
    link="$root/.$linux_user"
    if [[ -L "$link" && "$(readlink "$link")" == "$handle" ]]; then
        info "link exists: $link"
    elif [[ -e "$link" || -L "$link" ]]; then
        die "$link exists and is not a link to $handle"
    else
        run ln -s "$handle" "$link"
    fi
done

info "Created users/$handle (+ .$linux_user link) on NFS and scratch"
if [[ "$linux_user" != "$USER" ]]; then
    warn "directories are owned by $USER, not $linux_user; have $linux_user run this script, or chown as root"
fi
info "Reminder: set 'umask 002' in ~/.bashrc so new files stay group-accessible."
