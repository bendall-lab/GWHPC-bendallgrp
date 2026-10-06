#!/usr/bin/env bash
# Sync reference data from the NFS master (refDB) to the DSS scratch mirror.
# Use it to pre-stage everything, or from cron to repair a purged mirror.
# Workflows normally stage on demand via templates/project/rules/stage_reference.smk.
#
# Usage: sync-references.sh [-n|--dry-run] [REF ...]
#   REF: path under the refDB root (e.g. GRCh38). Default: sync the whole tree.
# Env overrides: MASTER_REFS, MIRROR_REFS (plus GROUP_ROOT, SCRATCH_ROOT, UNIX_GROUP)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
parse_common_flags "$@"

MASTER_REFS="${MASTER_REFS:-$GROUP_ROOT/shared_resources/references/refDB}"
MIRROR_REFS="${MIRROR_REFS:-$SCRATCH_ROOT/shared/references/refDB}"

command -v flock >/dev/null || die "flock not found (run this on Pegasus, not macOS)"
[[ -d "$MASTER_REFS" ]] || die "master not found: $MASTER_REFS"

rsync_flags=(-rl --size-only --omit-dir-times --chmod=Dug+rwx,Do+rx,Dg+s,Fug+rw,Fo+r)
[[ "$DRY_RUN" == 1 ]] && rsync_flags+=(-n -v)

sync_one() {   # sync_one REF  ('' = whole tree)
    local ref="$1" src dst lock
    src="$MASTER_REFS${ref:+/$ref}"
    dst="$MIRROR_REFS${ref:+/$ref}"
    lock="$MIRROR_REFS.locks/${ref//\//__}.lock"
    [[ -d "$src" ]] || die "no such master reference: $src"
    mkdir -p "$(dirname "$lock")" "$dst"
    info "syncing ${ref:-<all>}: $src -> $dst"
    # Same lock path convention as stage_reference.smk, so the two never collide.
    flock "$lock" rsync "${rsync_flags[@]}" --delete "$src/" "$dst/"
}

if [[ ${#REST_ARGS[@]} -eq 0 ]]; then
    sync_one ""
else
    for ref in "${REST_ARGS[@]}"; do sync_one "$ref"; done
fi
