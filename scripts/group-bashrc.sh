# Bendall group shell setup. Do not run directly: source it from ~/.bashrc
# (scripts/install-shell-setup.sh adds the line for you). See docs/11-shell-setup.md.
#
# Reached through a symlink (local/etc/group-bashrc.sh), so it uses fixed group paths
# instead of locating itself. Safe in non-interactive shells: only umask and environment
# variables are set there; aliases and functions are interactive-only.

BENDALLGRP_ROOT="${BENDALLGRP_ROOT:-/GWSPH/groups/bendallgrp}"       # NFS (Qumulo)
BENDALLGRP_SCRATCH="${BENDALLGRP_SCRATCH:-/scratch/bendallgrp}"      # DSS
BENDALLGRP_LOCAL="${BENDALLGRP_LOCAL:-$BENDALLGRP_ROOT/local}"       # bin/, etc/ (symlinks into the repo)
BENDALLGRP_TOOLS="${BENDALLGRP_TOOLS:-$BENDALLGRP_ROOT/software/tools/GWHPC-bendallgrp.git}"
export BENDALLGRP_ROOT BENDALLGRP_SCRATCH BENDALLGRP_LOCAL BENDALLGRP_TOOLS

# Personal directories: the dot-link named after your Linux username (docs/10-user-names.md)
export BENDALLGRP_HOME="$BENDALLGRP_ROOT/users/.$USER"
export BENDALLGRP_SCRATCH_HOME="$BENDALLGRP_SCRATCH/users/.$USER"

# Files you create stay group read/write (directories are setgid, so the group is inherited)
umask 002

# Group commands (appended, so they never shadow system commands): `init-user.sh`, `new-project.sh`, ...
case ":$PATH:" in *":$BENDALLGRP_LOCAL/bin:"*) ;; *) PATH="$PATH:$BENDALLGRP_LOCAL/bin" ;; esac
export PATH

case $- in *i*) ;; *) return 0 2>/dev/null || true ;; esac   # interactive shells only below

# Basic tools: load a module only when the command is not already on PATH
if type module >/dev/null 2>&1; then
    command -v sbatch >/dev/null 2>&1 || module load slurm 2>/dev/null
    command -v git    >/dev/null 2>&1 || module load git   2>/dev/null
    command -v curl   >/dev/null 2>&1 || module load curl  2>/dev/null
fi
export LMOD_COLORIZE="${LMOD_COLORIZE:-YES}"

# Node-local scratch is /local. Only override an unset or default TMPDIR, so a per-job TMPDIR
# that Slurm sets is never clobbered. Jobs share /local: use `mktemp -d -p "$TMPDIR"` for private space.
if [ -d /local ] && [ -w /local ] && { [ -z "${TMPDIR:-}" ] || [ "$TMPDIR" = /tmp ]; }; then
    export TMPDIR=/local
fi

# Job-queue shortcuts: qstat (my jobs), qcheck (history for given job ids), qstate JOBID (state only)
qstat()  { squeue -u "$USER" -o "%.10i  %.32j  %.8T  %.8M  %.6D  %.9P  %.19S   %R" "$@"; }
qcheck() { sacct -u "$USER" -o jobid,jobname,state,partition,start,end,nodelist "$@"; }
qstate() { sacct -u "$USER" -nXPo state -j "$@" | awk '{print tolower($0)}'; }

# Handle-aware wrappers: lsh, sqh, hpc_filter, hpc_whoami
[ -r "$BENDALLGRP_LOCAL/etc/hpc-aliases.sh" ] && . "$BENDALLGRP_LOCAL/etc/hpc-aliases.sh"

# Navigation
alias cdg='cd "$BENDALLGRP_ROOT"'
alias cds='cd "$BENDALLGRP_SCRATCH"'
alias cdme='cd "$BENDALLGRP_HOME"'
alias cdsme='cd "$BENDALLGRP_SCRATCH_HOME"'
alias cdproj='cd "$BENDALLGRP_ROOT/projects"'
alias cdref='cd "$BENDALLGRP_ROOT/shared_resources/references/refDB"'
