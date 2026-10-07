# 1. Storage tiers

| Tier | Path | Backing | Persistence | Use for |
|---|---|---|---|---|
| Group directory | `/GWSPH/groups/bendallgrp` | NFS, Qumulo cluster | Persistent | Code, configs, conda envs, final results, reference data |
| Group scratch | `/scratch/bendallgrp` | Lenovo DSS | Working space, not an archive | Raw inputs staged for analysis, intermediates (BAM/VCF), Snakemake working dirs |
| Node-local | `/local` | 800 GB SSD per node, shared with boot | Wiped when the job ends | Temp files for a single job (sort buffers, extraction) |

Pegasus documents the 800 GB onboard SSD ("used for boot and local scratch space") but not its mount point; `/local` is that disk on the compute nodes. Run `scripts/check-node-storage.sh` on a compute node (see the header of that script for an `srun` one-liner) to see whether it is writable for you. Also check whether `$TMPDIR` is set inside jobs.

Reference data lives in both tiers: the master on NFS and a purge-tolerant mirror on DSS ([Reference data](09-references.md)).

## Rules of thumb

- **Do not run heavy parallel I/O against NFS.** Hundreds of jobs writing BAMs to the group directory slows the group directory for everyone. Write intermediates to scratch.
- **Keep Snakemake's `.snakemake/` directory off NFS.** Run with the working directory on scratch ([Snakemake](06-snakemake.md)).
- **Scratch is not backup.** Anything irreplaceable (final results, code) belongs on the group directory. Scratch is purged on an ad hoc basis, per the Pegasus docs at the beginning of the month with a 30-day window, based on both modification time (mtime) and access time (atime). There is believed to be no snapshot or backup of the group directory either (**VERIFY** with RTS, hpchelp@gwu.edu), so keep a copy of irreplaceable data elsewhere.
- **Mind inode counts.** Conda environments and package caches contain very many small files ([Conda](04-conda.md)).
- **Keep usage modest.** No quota is published for the group directory or scratch, but RTS may contact the group if usage gets high. Clean up intermediates and drop what you no longer need.
