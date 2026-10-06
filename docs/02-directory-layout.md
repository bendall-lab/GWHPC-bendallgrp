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
│   ├── tools/GWHPC-bendallgrp.git/   # permanent checkout of this repo (admin-owned)
│   └── workflows/            # shared workflow repos (referenceDB, ...)
├── local/                    # group-authored glue, published from the checkout
│   ├── bin/                  # symlinks to executable scripts; on members' PATH
│   └── etc/                  # symlinks to sourced files (group-bashrc.sh, hpc-aliases.sh)
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

## `local/` vs `software/`

The split follows the Unix `/usr/local` vs `/opt` convention:

- **`software/`** holds things we *install or build*: conda environments, containers, workflow repositories. They have versions and come from elsewhere.
- **`local/`** holds things *we author for this group's environment*: the glue scripts and shell configuration. It is small, read by every member's shell, and put on `PATH`.

`local/bin/` and `local/etc/` contain only symlinks into `software/tools/GWHPC-bendallgrp.git/scripts/`, created by `scripts/link-local.sh`. The scripts find their helpers by resolving their own symlink, so they run the same way from `local/bin/` as from the checkout. `local/` is owner-writable (2755): members read and run it, and only the admin changes it.

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
