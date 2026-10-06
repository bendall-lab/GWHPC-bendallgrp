# Shared helpers, sourced by the other scripts. Not executable on its own.

GROUP_ROOT="${GROUP_ROOT:-/GWSPH/groups/bendallgrp}"     # NFS (Qumulo)
SCRATCH_ROOT="${SCRATCH_ROOT:-/scratch/bendallgrp}"       # Lenovo DSS
UNIX_GROUP="${UNIX_GROUP:-MG-bendallgrp}"                 # Unix group; differs from the directory name
LOCAL_ROOT="${LOCAL_ROOT:-$GROUP_ROOT/local}"             # group-authored scripts/config (like /usr/local)
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

# Group ownership is never set with chgrp: the group and scratch roots were created by an
# admin with group $UNIX_GROUP and the setgid bit, so everything made beneath them inherits it.

# dir_group PATH: print the group name that owns PATH (GNU stat, then BSD stat)
dir_group() { stat -c %G "$1" 2>/dev/null || stat -f %Sg "$1"; }

# check_root PATH: require an admin-created root with the right group and the setgid bit
check_root() {
    local path="$1"
    [[ -d "$path" ]] || die "$path does not exist; it must be created by an admin with group $UNIX_GROUP and setgid"
    [[ "$(dir_group "$path")" == "$UNIX_GROUP" ]] || warn "$path has group $(dir_group "$path"), expected $UNIX_GROUP"
    [[ -g "$path" ]] || warn "$path lacks the setgid bit, so new files will not inherit the group"
}

# make_dir PATH MODE: create PATH (group inherited via setgid) and set MODE
# (e.g. 2775 group-writable, 2755 group-readable only, 2770 group-only).
# Existing directories owned by someone else keep their mode.
make_dir() {
    local path="$1" mode="$2"
    run mkdir -p "$path"
    if [[ -d "$path" && ! -O "$path" ]]; then
        info "not owner of $path, leaving its mode as is"
        return 0
    fi
    run chmod "$mode" "$path"
    if [[ "$DRY_RUN" != 1 && "$(dir_group "$path")" != "$UNIX_GROUP" ]]; then
        warn "$path has group $(dir_group "$path"), expected $UNIX_GROUP (is its parent setgid?)"
    fi
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
