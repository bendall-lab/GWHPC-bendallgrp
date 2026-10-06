# 1. Storage tiers

| Tier | Path | Backing | Persistence | Use for |
|---|---|---|---|---|
| Group directory | `/GWSPH/groups/bendallgrp` | NFS, Qumulo cluster | Persistent | Code, configs, conda envs, final results, reference data |
| Group scratch | `/scratch/bendallgrp` | Lenovo DSS | Working space, not an archive | Raw inputs staged for analysis, intermediates (BAM/VCF), Snakemake working dirs |
| Node-local | `/local` (**VERIFY**) | 800 GB SSD per node, shared with boot | Wiped when the job ends | Temp files for a single job (sort buffers, extraction) |

Pegasus documents the 800 GB onboard SSD ("used for boot and local scratch space") but not its mount point. The group admin's own `~/.bashrc` sets `TMPDIR=/local`, so `/local` is the working assumption. Run `scripts/check-node-storage.sh` on a compute node (see the header of that script for an `srun` one-liner) to confirm whether `/local` exists and is writable. Also check whether `$TMPDIR` is set inside jobs.

Reference data lives in both tiers: the master on NFS and a purge-tolerant mirror on DSS ([Reference data](09-references.md)).

## Rules of thumb

- **Do not run heavy parallel I/O against NFS.** Hundreds of jobs writing BAMs to the group directory slows the group directory for everyone. Write intermediates to scratch.
- **Keep Snakemake's `.snakemake/` directory off NFS.** Run with the working directory on scratch ([Snakemake](06-snakemake.md)).
- **Scratch is not backup.** Anything irreplaceable (final results, code) belongs on the group directory. Scratch has a purge policy (reportedly 60 or 90 days, enforced when scratch fills, likely by access time; **VERIFY** with RTS). **VERIFY** the group directory snapshot/backup policy too, with RTS (rtshelp@gwu.edu) and record the answers here.
- **Mind inode counts.** Conda environments and package caches contain very many small files ([Conda](04-conda.md)).
- **Check quotas.** **VERIFY** the group quota on `/GWSPH/groups/bendallgrp` and on scratch, and the command to view usage.
