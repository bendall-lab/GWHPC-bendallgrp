#!/usr/bin/env bash
# Report which storage tiers are visible and writable. Run it ON A COMPUTE NODE
# (not a login node) to confirm node-local scratch, e.g.:
#   srun --partition=cpu --cpus-per-task=1 --mem=1G --time=0-00:05:00 scripts/check-node-storage.sh
# Resolve symlinks so the script works when run via local/bin/ (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "host: $(hostname)   job: ${SLURM_JOB_ID:-none}   TMPDIR=${TMPDIR:-<unset>}"
echo
for p in "$GROUP_ROOT" "$SCRATCH_ROOT" /local /scratch /tmp "${TMPDIR:-}"; do
    [[ -n "$p" ]] || continue
    if [[ -d "$p" ]]; then
        w=no; [[ -w "$p" ]] && w=yes
        printf '%-32s writable=%-3s ' "$p" "$w"
        df -hP "$p" | awk 'NR==2 {print $6 " (" $1 ", " $2 " total, " $4 " free)"}'
    else
        printf '%-32s (not present)\n' "$p"
    fi
done
echo
echo "filesystem types:"
findmnt -no TARGET,FSTYPE,SOURCE "$GROUP_ROOT" "$SCRATCH_ROOT" /local /tmp 2>/dev/null || mount | grep -E "$GROUP_ROOT|$SCRATCH_ROOT|/local" || true
