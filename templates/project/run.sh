#!/usr/bin/env bash
# Launch the workflow: code/profile from NFS, working directory (and .snakemake/) on scratch.
# Usage: ./run.sh [extra snakemake args, e.g. -n for a dry run]
# Run inside tmux/screen or an sbatch wrapper; this process must stay alive while jobs run.
set -euo pipefail

PROJECT_DIR="@PROJECT_DIR@"
WORKDIR="@SCRATCH_ROOT@/users/.${USER}/@PROJECT_NAME@"   # dot-link to users/<handle>

mkdir -p "$WORKDIR"
exec snakemake \
    --snakefile "$PROJECT_DIR/Snakefile" \
    --directory "$WORKDIR" \
    --workflow-profile "$PROJECT_DIR/profiles/slurm" \
    "$@"
