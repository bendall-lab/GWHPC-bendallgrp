#!/usr/bin/env bash
# Create a new Snakemake project: code skeleton on NFS, working directory on scratch.
#
# Usage: new-project.sh [-n|--dry-run] PROJECT_NAME
#   PROJECT_NAME: letters, digits, '_' and '-' only, e.g. 2026_rnaseq_screen
set -euo pipefail
# Resolve symlinks so the script works when run via local/bin/ (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
parse_common_flags "$@"

name="${REST_ARGS[0]:-}"
[[ -n "$name" ]] || die "usage: new-project.sh [-n] PROJECT_NAME"
[[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid project name: $name"

template="$(cd "$SCRIPT_DIR/../templates/project" && pwd)"
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
    chmod -R g+rwX "$proj"      # group is inherited from the setgid parent
fi

info "Project : $proj"
info "Workdir : $work   (run Snakemake from here via $proj/run.sh)"
