#!/usr/bin/env bash
# Create the group directory layout on NFS (Qumulo) and shared scratch layout on DSS.
# Idempotent: safe to re-run. See docs/02-directory-layout.md for the rationale.
#
# Usage: init-group-dir.sh [-n|--dry-run]
# Env overrides: GROUP_ROOT, SCRATCH_ROOT, UNIX_GROUP
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
parse_common_flags "$@"

info "Group dir : $GROUP_ROOT"
info "Scratch   : $SCRATCH_ROOT"
info "Unix group: $UNIX_GROUP"

# --- NFS (Qumulo): persistent, small files ---------------------------------
make_dir "$GROUP_ROOT"                               2775
make_dir "$GROUP_ROOT/admin"                         2770   # grants, protocols, onboarding
make_dir "$GROUP_ROOT/shared_resources"              2775
make_dir "$GROUP_ROOT/shared_resources/references"   2775   # master copy; built by the referenceDB workflow
make_dir "$GROUP_ROOT/shared_resources/references/refDB" 2775
make_dir "$GROUP_ROOT/shared_resources/databases"    2755
make_dir "$GROUP_ROOT/software"                      2775
make_dir "$GROUP_ROOT/software/conda"                2775
make_dir "$GROUP_ROOT/software/conda/envs"           2755   # shared, maintainer-managed
make_dir "$GROUP_ROOT/software/conda/snakemake_envs" 2775   # snakemake --conda-prefix target
make_dir "$GROUP_ROOT/software/containers"           2775
make_dir "$GROUP_ROOT/software/workflows"            2775   # shared workflow repos (e.g. referenceDB)
make_dir "$GROUP_ROOT/projects"                      2775
make_dir "$GROUP_ROOT/users"                         2775   # per-user dirs made by init-user.sh
make_dir "$GROUP_ROOT/archive"                       2755   # finished projects, read-only

# --- DSS scratch: large/volatile --------------------------------------------
make_dir "$SCRATCH_ROOT"                             2775
make_dir "$SCRATCH_ROOT/users"                       2775
make_dir "$SCRATCH_ROOT/shared"                      2775   # data several members read (FASTQs, indexes)
make_dir "$SCRATCH_ROOT/shared/references"           2775   # mirror of shared_resources/references
make_dir "$SCRATCH_ROOT/shared/references/refDB"     2775

info "Done."
