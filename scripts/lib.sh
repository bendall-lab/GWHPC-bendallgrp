# Shared helpers, sourced by the other scripts. Not executable on its own.

GROUP_ROOT="${GROUP_ROOT:-/GWSPH/groups/bendallgrp}"     # NFS (Qumulo)
SCRATCH_ROOT="${SCRATCH_ROOT:-/scratch/bendallgrp}"       # Lenovo DSS
UNIX_GROUP="${UNIX_GROUP:-MG-bendallgrp}"                 # Unix group; differs from the directory name
DRY_RUN="${DRY_RUN:-0}"
USER_MAP="${USER_MAP:-$GROUP_ROOT/admin/user_map.tsv}"    # linux_user<TAB>handle<TAB>full_name<TAB>added

info() { printf '[info] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
die()  { printf '[error] %s\n' "$*" >&2; exit 1; }

# run CMD...: print the command, and execute it unless DRY_RUN=1
run() {
    if [[ "$DRY_RUN" == 1 ]]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# make_dir PATH MODE: create PATH with group ownership, setgid, and MODE
# (e.g. 2775 group-writable, 2755 group-readable only, 2770 group-only)
make_dir() {
    local path="$1" mode="$2"
    run mkdir -p "$path"
    run chgrp "$UNIX_GROUP" "$path" || warn "chgrp $UNIX_GROUP failed on $path"
    run chmod "$mode" "$path"
}

parse_common_flags() {
    # Sets DRY_RUN and leaves remaining args in REST_ARGS.
    REST_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1 ;;
            *) REST_ARGS+=("$1") ;;
        esac
        shift
    done
}

# user map lookups (see docs/10-user-names.md); print nothing if not found
map_handle_for() { [[ -r "$USER_MAP" ]] && awk -F'\t' -v u="$1" '!/^#/ && $1==u {print $2; exit}' "$USER_MAP"; }
map_user_for()   { [[ -r "$USER_MAP" ]] && awk -F'\t' -v h="$1" '!/^#/ && $2==h {print $1; exit}' "$USER_MAP"; }
