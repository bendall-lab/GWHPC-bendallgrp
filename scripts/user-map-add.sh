#!/usr/bin/env bash
# ADMIN ONLY: add a member to the Linux username <-> handle map.
# Deliberately not linked into local/bin (see link-local.sh); run it from the checkout.
# The map lives on the cluster (default $GROUP_ROOT/admin/user_map.tsv), never in this repo.
# Members read the map with the user-map-lookup and user-map-list shell functions (hpc-aliases.sh).
#
# Usage: user-map-add.sh [-n|--dry-run] LINUX_USER HANDLE ["Full Name"] [EMAIL] [ROLE]
# ROLE is "user" (default) or "admin".
# The map must already exist with you as an admin (bootstrap: docs/setup-admin.md, Prerequisites).
# Env overrides: USER_MAP, GROUP_ROOT
set -euo pipefail
# Resolve symlinks so the script works when run via a link (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
parse_common_flags "$@"
require_admin

linux_user="${REST_ARGS[0]:-}"; handle="${REST_ARGS[1]:-}"; full="${REST_ARGS[2]:-}"; email="${REST_ARGS[3]:-}"; role="${REST_ARGS[4]:-user}"
[[ -n "$linux_user" && -n "$handle" ]] || die "usage: user-map-add.sh [-n] LINUX_USER HANDLE [\"Full Name\"] [EMAIL] [ROLE]"
[[ "$linux_user" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid linux user: $linux_user"
[[ "$handle" =~ ^[a-z][a-z0-9_-]*$ ]]       || die "handle must be lowercase letters, digits, '_' or '-': $handle"
[[ -z "$email" || "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]] || die "invalid email: $email"
[[ "$role" == user || "$role" == admin ]] || die "role must be 'user' or 'admin': $role"
if [[ -r "$USER_MAP" ]]; then
    [[ -z "$(map_handle_for "$linux_user")" ]] || die "$linux_user already mapped to $(map_handle_for "$linux_user")"
    [[ -z "$(map_user_for "$handle")" ]]       || die "handle $handle already used by $(map_user_for "$handle")"
fi
line="$(printf '%s\t%s\t%s\t%s\t%s\t%s' "$linux_user" "$handle" "$full" "$(date +%F)" "$email" "$role")"
if [[ "$DRY_RUN" == 1 ]]; then printf '[dry-run] append to %s: %s\n' "$USER_MAP" "$line"
else printf '%s\n' "$line" >> "$USER_MAP"; info "added $linux_user -> $handle"; fi
