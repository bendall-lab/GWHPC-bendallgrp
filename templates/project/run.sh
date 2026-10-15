#!/usr/bin/env bash
# Launch the workflow: code/profile from NFS, working directory (and .snakemake/) on scratch.
# Usage: ./run.sh [extra snakemake args, e.g. -n for a dry run]
# With pixi.toml present it runs `pixi run --locked`: the lock file must match pixi.toml (run `pixi lock` after edits).
# Run inside tmux/screen or an sbatch wrapper; this process must stay alive while jobs run.
set -euo pipefail

PROJECT_DIR="@PROJECT_DIR@"
WORKDIR="@SCRATCH_ROOT@/users/.${USER}/@PROJECT_NAME@"   # dot-link to users/<handle>

# Software: the project's pixi environment if it has a pixi.toml (needs `module load pixi`),
# otherwise whatever `snakemake` is on PATH (e.g. `module load snakemake`).
RUNNER=(snakemake)
if [[ -f "$PROJECT_DIR/pixi.toml" ]]; then
    command -v pixi >/dev/null || { echo "run.sh: pixi not found; run: module load pixi" >&2; exit 1; }
    RUNNER=(pixi run --locked --manifest-path "$PROJECT_DIR/pixi.toml" snakemake)
fi

mkdir -p "$WORKDIR"
exec "${RUNNER[@]}" \
    --snakefile "$PROJECT_DIR/Snakefile" \
    --directory "$WORKDIR" \
    --workflow-profile "$PROJECT_DIR/profiles/slurm" \
    "$@"
