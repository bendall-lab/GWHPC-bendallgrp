 #!/usr/bin/env bash
# ADMIN ONLY: publish this repo's modulefiles/ to $GROUP_ROOT/software/modulefiles/.
# Deliberately a COPY, not symlinks (unlike local/bin): a `git pull` or branch switch in the
# checkout must never change, or break, `module load` for members. Published modulefiles are
# release artifacts that change only when you run this script. Not linked into local/bin.
#
# Usage: install-modulefiles.sh [-n|--dry-run] [--delete]
#   --dry-run  list what would change and show a diff of modified files; change nothing
#   --delete   also remove published modulefiles that are no longer in the repo
#              (off by default: deleting a modulefile breaks `module load` for anyone using it)
# Env overrides: GROUP_ROOT, MODULEFILES_DEST
set -euo pipefail
# Resolve symlinks so the script works when run via a link (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

delete=0
args=()
for a in "$@"; do
    case "$a" in
        --delete) delete=1 ;;
        *) args+=("$a") ;;
    esac
done
parse_common_flags "${args[@]+"${args[@]}"}"
require_admin

src="$(cd "$SCRIPT_DIR/.." && pwd)/modulefiles"
dest="${MODULEFILES_DEST:-$GROUP_ROOT/software/modulefiles}"
[[ -d "$src" ]]  || die "no modulefiles/ directory in the repo: $src"
[[ -d "$dest" ]] || die "$dest does not exist; run init-group-dir.sh first"

# Syntax-check every modulefile when a Lua compiler is available.
lua_check=""
for c in luac luac5.4 luac5.3 luac5.1; do command -v "$c" >/dev/null 2>&1 && { lua_check="$c"; break; }; done
if [[ -n "$lua_check" ]]; then
    while IFS= read -r -d '' f; do
        "$lua_check" -p "$f" || die "Lua syntax error in $f"
    done < <(find "$src" -name '*.lua' -print0)
    info "Lua syntax OK ($lua_check)"
else
    warn "no luac found; skipping the Lua syntax check (use 'module load' to test after installing)"
fi

flags=(-rlp --checksum --itemize-changes --omit-dir-times
       --chmod=Du=rwx,Dgo=rx,Dg+s,Fu=rw,Fgo=r)
[[ "$delete" == 1 ]] && flags+=(--delete)
[[ "$DRY_RUN" == 1 ]] && flags+=(-n)

info "Publishing $src -> $dest"
rsync "${flags[@]}" "$src/" "$dest/"

if [[ "$DRY_RUN" == 1 ]]; then
    info "Dry run: diff of files that differ (installed vs repo)"
    diff -ru "$dest" "$src" || true
else
    info "Done. Test with: module use $dest; module avail"
fi
