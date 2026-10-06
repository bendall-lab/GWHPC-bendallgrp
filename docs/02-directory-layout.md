# 2. Directory layout

Created by `scripts/init-group-dir.sh` (idempotent; `--dry-run` shows what it would do).

## Group directory (NFS)

```text
/GWSPH/groups/bendallgrp/
├── admin/                    # grants, protocols, onboarding; group-only (2770)
├── shared_resources/
│   ├── references/refDB/     # master reference data, built by referenceDB (see 09-references.md)
│   └── databases/            # dbSNP, gnomAD, UniProt, ...
├── software/
│   ├── conda/
│   │   ├── envs/             # shared, maintainer-managed environments
│   │   └── snakemake_envs/   # Snakemake --conda-prefix target
│   ├── containers/           # Apptainer/Singularity images
│   └── workflows/            # shared workflow repos (referenceDB, ...)
├── projects/                 # one directory per project (below)
├── users/<handle>/           # small personal files; .<linux_user> is a symlink to it (10-user-names.md)
└── archive/                  # finished projects, read-only
```

## Scratch (DSS)

```text
/scratch/bendallgrp/
├── users/<handle>/<project>/ # Snakemake working directory (also users/.<linux_user>/...)
└── shared/
    └── references/refDB/     # purge-tolerant mirror of the NFS master (09-references.md)
```

## Per-project layout

Copied from `templates/project/` by `scripts/new-project.sh`:

```text
projects/<project>/                    # NFS, a git repository
├── README.md                          # question, owner, data origin
├── Snakefile
├── config.yaml
├── run.sh                             # runs Snakemake with workdir on scratch
├── profiles/slurm/config.yaml         # Snakemake 9+ profile
├── envs/                              # per-rule conda env YAMLs
├── docs/                              # sample sheets, metadata, notes
└── results/                           # final tables and figures only

/scratch/bendallgrp/users/<handle>/<project>/   # created at project start
├── .snakemake/
├── 01_raw/                            # symlinks or staged inputs
└── 02_intermediates/                  # BAMs, VCFs, etc.
```

## Conventions

- Raw data is never modified. Store it once, `chmod -R a-w`, and symlink it into workflows.
- Numeric prefixes (`01_raw`, `02_intermediates`) show processing order.
- Use relative paths inside a project; absolute paths belong in `config.yaml`.
- Finished projects: copy `results/`, code, and a record of software versions into `archive/`, then clean the scratch directory.
