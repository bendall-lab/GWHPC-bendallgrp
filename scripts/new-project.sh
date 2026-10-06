#!/usr/bin/env bash
# Create a new Snakemake project: code skeleton on NFS, working directory on scratch.
#
# Usage: new-project.sh [-n|--dry-run] PROJECT_NAME
#   PROJECT_NAME: letters, digits, '_' and '-' only, e.g. 2026_rnaseq_screen
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
parse_common_flags "$@"

name="${REST_ARGS[0]:-}"
[[ -n "$name" ]] || die "usage: new-project.sh [-n] PROJECT_NAME"
[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid project name: $name"

template="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates/project" && pwd)"
proj="$GROUP_ROOT/projects/$name"
work="$SCRATCH_ROOT/users/.$USER/$name"      # dot-link to users/<handle>

[[ ! -e "$proj" ]] || die "$proj already exists"
[[ "$DRY_RUN" == 1 || -d "$SCRATCH_ROOT/users/.$USER" ]] || die "run scripts/init-user.sh first"

make_dir "$proj" 2775
run cp -R "$template/." "$proj/"
make_dir "$proj/results" 2775
make_dir "$work" 2775

# Fill in placeholders in the copied templates.
if [[ "$DRY_RUN" != 1 ]]; then
    find "$proj" -type f \( -name '*.yaml' -o -name '*.md' -o -name '*.sh' -o -name '*.smk' \) -print0 |
        while IFS= read -r -d '' f; do
            sed -i.bak \
                -e "s|@PROJECT_NAME@|$name|g" \
                -e "s|@PROJECT_DIR@|$proj|g" \
                -e "s|@GROUP_ROOT@|$GROUP_ROOT|g" \
                -e "s|@SCRATCH_ROOT@|$SCRATCH_ROOT|g" "$f"
            rm -f "$f.bak"
        done
    chmod +x "$proj/run.sh"
    chmod -R g+rwX "$proj"
    chgrp -R "$UNIX_GROUP" "$proj" || warn "chgrp -R $UNIX_GROUP failed on $proj"
fi

info "Project : $proj"
info "Workdir : $work   (run Snakemake from here via $proj/run.sh)"
