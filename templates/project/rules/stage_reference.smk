# Stage reference data from the NFS master copy to the DSS scratch mirror.
# See docs/09-references.md for the rationale (purge policy, partial purges, locking).
#
# Usage in a workflow (after `configfile:`):
#     include: "rules/stage_reference.smk"
#     rule align:
#         input:
#             staged=ref_staged("GRCh38"),
#             index=ref_path("GRCh38", "star_2.7.11b"),   # mirror path, on DSS
#
# `ref` is a path under the refDB root, e.g. "GRCh38" or "genomes/GRCh38".
import os

REF_MASTER = config["references"]["master"]
REF_MIRROR = config["references"]["mirror"]


def ref_path(ref, *parts):
    """Path inside the scratch mirror. Pair with ref_staged(ref) as a rule input."""
    return os.path.join(REF_MIRROR, ref, *parts)


def ref_staged(ref):
    """Marker that triggers staging of `ref`."""
    return f"ref_staged/{ref}.synced"


rule stage_reference:
    output:
        # temp(): marker is removed once consumers finish, so staging re-runs (and
        # repairs any purged files) on the next invocation that needs the reference.
        temp("ref_staged/{ref}.synced"),
    wildcard_constraints:
        ref=r"[^.].*",
    params:
        src=lambda wc: os.path.join(REF_MASTER, wc.ref),
        dst=lambda wc: os.path.join(REF_MIRROR, wc.ref),
        lock=lambda wc: f"{REF_MIRROR}.locks/{wc.ref.replace('/', '__')}.lock",
    threads: 1
    resources:
        mem_mb=1000,
        runtime=120,
    shell:
        r"""
        set -euo pipefail
        [ -d "{params.src}" ] || {{ echo "missing master reference: {params.src}" >&2; exit 1; }}
        mkdir -p "$(dirname "{params.lock}")" "{params.dst}"
        # --size-only and no -t: the mirror's mtimes are copy time, and unchanged files
        # are skipped without being read. rsync also restores files removed by a purge.
        flock "{params.lock}" rsync -rl --size-only --delete --omit-dir-times \
            --chmod=Dug+rwx,Do+rx,Dg+s,Fug+rw,Fo+r "{params.src}/" "{params.dst}/"
        mkdir -p "$(dirname {output})"
        touch {output}
        """
