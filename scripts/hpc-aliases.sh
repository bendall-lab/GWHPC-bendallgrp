# Source from ~/.bashrc (loaded for you by group-bashrc.sh; zsh also works):
#   source /GWSPH/groups/bendallgrp/local/etc/hpc-aliases.sh
# Shows human-readable handles in place of Linux usernames. Output only; nothing is modified.
#
#   hpc_filter          stdin filter: replaces whole-word Linux usernames with handles
#   lsh [ls args]       ls -l with owner/group names mapped
#   sqh [args]          squeue with usernames mapped
#   hpc_whoami          your handle
#   user-map-lookup N   print the handle for a Linux username, or the username for a handle
#   user-map-list       print the whole map as a table
#
# Opt in to `ls` itself showing handles by setting, BEFORE this file is sourced:
#   export HPC_WRAP_LS=1
# On a terminal, long listings (-l, -g, -o, --format=long) are filtered; everything else, and
# any ls in a pipe or script, is the normal ls. This replaces any `alias ls=...` you have.
#
# Only tokens that exactly equal a Linux username are replaced, so paths like
# users/.u12345 (the dot-link) and users/<handle> are left alone. Columns may
# shift when a handle is longer than the username. The map is read-only here; adding
# members is admin-only (scripts/user-map-add.sh).

HPC_USER_MAP="${HPC_USER_MAP:-/GWSPH/groups/bendallgrp/admin/user_map.tsv}"

hpc_filter() {
    [ -r "$HPC_USER_MAP" ] || { cat; return; }
    awk -v mapfile="$HPC_USER_MAP" '
        BEGIN {
            while ((getline l < mapfile) > 0) {
                if (l ~ /^#/ || l == "") continue
                split(l, a, "\t"); m[a[1]] = a[2]
            }
        }
        {
            out = ""; s = $0
            while (match(s, /[A-Za-z0-9_.\/-]+/)) {
                pre = substr(s, 1, RSTART - 1); tok = substr(s, RSTART, RLENGTH)
                s = substr(s, RSTART + RLENGTH)
                if (tok in m) tok = m[tok]
                out = out pre tok
            }
            print out s
        }'
}

lsh()  { command ls -l "$@" | hpc_filter; }
sqh()  { squeue "$@" | hpc_filter; }
hpc_whoami() { echo "$USER" | hpc_filter; }

# user-map-lookup NAME: Linux username -> handle, or handle -> Linux username
user-map-lookup() {
    [ -n "${1:-}" ] || { echo "usage: user-map-lookup NAME" >&2; return 2; }
    [ -r "$HPC_USER_MAP" ] || { echo "no map at $HPC_USER_MAP" >&2; return 1; }
    awk -F'\t' -v n="$1" '
        /^#/ { next }
        $1 == n { print $2; f = 1; exit }
        $2 == n { print $1; f = 1; exit }
        END { exit !f }' "$HPC_USER_MAP" || { echo "not found: $1" >&2; return 1; }
}

# user-map-list: the whole map as a table (empty fields shown as '-')
user-map-list() {
    [ -r "$HPC_USER_MAP" ] || { echo "no map at $HPC_USER_MAP" >&2; return 1; }
    awk -F'\t' -v OFS='\t' '{ for (i = 1; i <= NF; i++) if ($i == "") $i = "-"; print }' "$HPC_USER_MAP" |
        column -t -s "$(printf '\t')"
}

# --- opt-in ls wrapper ---------------------------------------------------------------
# _hpc_ls_is_long ARGS...: true if ls would print owner/group columns (-l, -g, -o, --format=long)
_hpc_ls_is_long() {
    local a
    for a in "$@"; do
        case "$a" in
            --) break ;;
            --format=long|--format=verbose) return 0 ;;
            --*) ;;
            -*[lgo]*) return 0 ;;
        esac
    done
    return 1
}

# The unalias must be its own command, run before the definition below is parsed: bash and zsh
# refuse to define a function whose name is an active alias.
[ "${HPC_WRAP_LS:-0}" = 1 ] && unalias ls 2>/dev/null

if [ "${HPC_WRAP_LS:-0}" = 1 ]; then
    function ls {
        if [ -t 1 ] && _hpc_ls_is_long "$@"; then
            command ls --color=always "$@" | hpc_filter
            return "${PIPESTATUS[0]:-${pipestatus[1]}}"
        fi
        command ls --color=auto "$@"
    }
fi
