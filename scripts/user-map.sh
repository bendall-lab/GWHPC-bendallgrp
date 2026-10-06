#!/usr/bin/env bash
# Manage the mapping between Linux usernames and human-readable handles.
# The map lives on the cluster (default $GROUP_ROOT/admin/user_map.tsv), never in this repo.
#
# Usage:
#   user-map.sh add [-n] LINUX_USER HANDLE ["Full Name"]
#   user-map.sh lookup NAME        # NAME is a linux user or a handle; prints the other one
#   user-map.sh list
# Env overrides: USER_MAP, GROUP_ROOT, UNIX_GROUP
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cmd="${1:-}"; shift || true

case "$cmd" in
    add)
        parse_common_flags "$@"
        linux_user="${REST_ARGS[0]:-}"; handle="${REST_ARGS[1]:-}"; full="${REST_ARGS[2]:-}"
        [[ -n "$linux_user" && -n "$handle" ]] || die "usage: user-map.sh add [-n] LINUX_USER HANDLE [\"Full Name\"]"
        [[ "$linux_user" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid linux user: $linux_user"
        [[ "$handle" =~ ^[a-z][a-z0-9_-]*$ ]]       || die "handle must be lowercase letters, digits, '_' or '-': $handle"
        if [[ -r "$USER_MAP" ]]; then
            [[ -z "$(map_handle_for "$linux_user")" ]] || die "$linux_user already mapped to $(map_handle_for "$linux_user")"
            [[ -z "$(map_user_for "$handle")" ]]       || die "handle $handle already used by $(map_user_for "$handle")"
        fi
        if [[ ! -e "$USER_MAP" ]]; then
            run mkdir -p "$(dirname "$USER_MAP")"
            if [[ "$DRY_RUN" != 1 ]]; then
                printf '# linux_user\thandle\tfull_name\tadded\n' > "$USER_MAP"
                chgrp "$UNIX_GROUP" "$USER_MAP" 2>/dev/null || warn "chgrp $UNIX_GROUP failed on $USER_MAP"
                chmod 664 "$USER_MAP"
            fi
        fi
        line="$(printf '%s\t%s\t%s\t%s' "$linux_user" "$handle" "$full" "$(date +%F)")"
        if [[ "$DRY_RUN" == 1 ]]; then printf '[dry-run] append to %s: %s\n' "$USER_MAP" "$line"
        else printf '%s\n' "$line" >> "$USER_MAP"; info "added $linux_user -> $handle"; fi
        ;;
    lookup)
        name="${1:-}"; [[ -n "$name" ]] || die "usage: user-map.sh lookup NAME"
        out="$(map_handle_for "$name")"; [[ -n "$out" ]] || out="$(map_user_for "$name")"
        [[ -n "$out" ]] || die "not found: $name"
        echo "$out"
        ;;
    list)
        [[ -r "$USER_MAP" ]] || die "no map at $USER_MAP"
        # show empty fields as '-' so column -t doesn't collapse them
        awk -F'\t' -v OFS='\t' '{ for (i = 1; i <= NF; i++) if ($i == "") $i = "-"; print }' "$USER_MAP" |
            column -t -s "$(printf '\t')"
        ;;
    *) die "usage: user-map.sh {add|lookup|list} ..." ;;
esac
