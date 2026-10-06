# GWHPC-bendallgrp

Group directory conventions, tooling, and documentation for the Bendall group on GW's Pegasus HPC cluster.

- Group directory (NFS, Qumulo): `/GWSPH/groups/bendallgrp`
- Scratch (Lenovo DSS): `/scratch/bendallgrp`
- Node-local scratch: `/local` (unverified)

## Documentation

Start at [docs/index.md](docs/index.md):

1. [Storage tiers](docs/01-storage-tiers.md)
2. [Directory layout](docs/02-directory-layout.md)
3. [Permissions and access](docs/03-permissions.md)
4. [Conda and software](docs/04-conda.md)
5. [SLURM and partitions](docs/05-slurm-and-partitions.md)
6. [Snakemake 9+ workflows](docs/06-snakemake.md)
7. [Starting a new project](docs/07-new-project.md)
8. [Publishing these docs](docs/08-publishing-docs.md)
9. [Reference data](docs/09-references.md)
10. [Usernames and handles](docs/10-user-names.md)

## Contents

- `scripts/`: `init-group-dir.sh`, `init-user.sh`, `new-project.sh`, `check-node-storage.sh`, `sync-references.sh`, `user-map.sh`, `hpc-aliases.sh` (sourced)
- `templates/project/`: Snakemake 9+ project skeleton with a SLURM profile and a reference staging rule

## Quick start

```bash
scripts/init-user.sh
scripts/new-project.sh <project_name>
```
