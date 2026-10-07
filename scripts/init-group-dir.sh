#!/usr/bin/env bash
# Create the group directory layout on NFS (Qumulo) and shared scratch layout on DSS.
# ADMIN ONLY: requires your user to have role "admin" in the user map, which must be
# bootstrapped by hand first (docs/setup-admin.md, Prerequisites).
# Idempotent: safe to re-run. See docs/02-directory-layout.md for the rationale.
#
# Usage: init-group-dir.sh [-n|--dry-run]
# Env overrides: GROUP_ROOT, SCRATCH_ROOT, UNIX_GROUP
set -euo pipefail
# Resolve symlinks so the script works when run via local/bin/ (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
parse_common_flags "$@"
require_admin

info "Group dir : $GROUP_ROOT"
info "Scratch   : $SCRATCH_ROOT"
info "Unix group: $UNIX_GROUP"

# The two roots are created by an admin (group $UNIX_GROUP, setgid). We only verify them
# and build beneath them; subdirectories inherit the group, so no chgrp is needed.
check_root "$GROUP_ROOT"
check_root "$SCRATCH_ROOT"

# --- NFS (Qumulo): persistent, small files ---------------------------------
make_dir "$GROUP_ROOT/admin"                        2770   # grants, protocols, onboarding
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
make_dir "$GROUP_ROOT/software/tools"                2755   # permanent checkout of this repo
make_dir "$LOCAL_ROOT"                               2755   # group-authored glue; filled by link-local.sh
make_dir "$LOCAL_ROOT/bin"                           2755
make_dir "$LOCAL_ROOT/etc"                           2755
make_dir "$GROUP_ROOT/projects"                      2775
make_dir "$GROUP_ROOT/users"                         2775   # per-user dirs made by init-user.sh
make_dir "$GROUP_ROOT/archive"                       2755   # finished projects, read-only

# --- DSS scratch: large/volatile --------------------------------------------
make_dir "$SCRATCH_ROOT/users"                      2775
make_dir "$SCRATCH_ROOT/shared"                      2775   # data several members read (FASTQs, indexes)
make_dir "$SCRATCH_ROOT/shared/references"           2775   # mirror of shared_resources/references
make_dir "$SCRATCH_ROOT/shared/references/refDB"     2775

info "Done."
