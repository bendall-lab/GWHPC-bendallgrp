# First-time user setup

What a new group member does once, in order. The group admin does their part first ([First-time admin setup](setup-admin.md)).

## 0. Before you start

Ask the admin to:

1. Get you added to the Unix group `MG-bendallgrp` (via RTS).
2. Add you to the group's username map and tell you your **handle**, the human-readable name used for your directories.

Then log in to Pegasus (SSH keys and two-factor setup are covered in the [GW HPC onboarding guide](https://github.com/gwuniversity/hpc-onboarding)) and check:

```bash
id                                        # MG-bendallgrp should be listed
ls /GWSPH/groups/bendallgrp               # you should be able to read the group directory
```

If `MG-bendallgrp` is missing from `id`, log out and back in; if it is still missing, the group change has not reached your account yet.

## 1. Install the group shell setup

```bash
/GWSPH/groups/bendallgrp/local/bin/install-shell-setup.sh --dry-run    # preview
/GWSPH/groups/bendallgrp/local/bin/install-shell-setup.sh
source ~/.bashrc
```

This adds a short marked block to your `~/.bashrc` (and creates `~/.bash_profile` if you have no login-shell file, so login shells read it). It sets `umask 002` so files you create are group-writable, puts the group commands on your `PATH`, and adds shortcuts such as `cdg`, `cdme`, `qstat` and `lsh`. The full list is in [Group shell setup](11-shell-setup.md). To undo it, delete that block.

## 2. Create your directories

```bash
init-user.sh
```

This creates `users/<handle>` on the group directory and on scratch, plus a link named after your Linux username (`users/.<linux_user>`). It fails with a message if the admin has not added you to the map yet. Check it:

```bash
cdme && pwd -P                            # your directory on NFS
cdsme && pwd -P                           # your directory on scratch
```

## 3. Get Snakemake

Workflows here use Snakemake 9 or newer with the SLURM executor plugin:

```bash
mamba create -n snakemake -c conda-forge -c bioconda snakemake snakemake-executor-plugin-slurm
```

Shared environments for specific tools are in `software/conda/envs/`; see [Conda and software](04-conda.md) for how to use them and for the conda cache settings.

## 4. Start a project

```bash
new-project.sh 2026_my_project            # project code on NFS, workdir on scratch
cd /GWSPH/groups/bendallgrp/projects/2026_my_project
git init
./run.sh -n                               # dry run
```

Edit the example rules in `Snakefile`, list your samples in `docs/samples.tsv`, and adjust `profiles/slurm/config.yaml` for your jobs. Run `./run.sh` inside `tmux` or `screen` (or an `sbatch` wrapper): Snakemake has to stay alive while its jobs are queued and running. More detail is in [Starting a new project](07-new-project.md) and [Snakemake 9+ workflows](06-snakemake.md).

## Where things go

| What | Where | Why |
|---|---|---|
| Code, configs, final results | `projects/<project>/` (NFS) | persistent; version with git |
| Raw inputs, intermediates, `.snakemake/` | `/scratch/bendallgrp/users/<handle>/<project>/` | fast parallel I/O; **purged when scratch fills** |
| Reference genomes and indexes | read from the scratch mirror via the staging rule | see [Reference data](09-references.md) |
| Temporary files inside a job | `$TMPDIR` (`/local`, node-local) | fastest; wiped when the job ends |

Do not run heavy parallel I/O against the group directory, and keep anything irreplaceable off scratch ([Storage tiers](01-storage-tiers.md)).

## Getting help

- **Cluster problems:** hpchelp@gwu.edu, office hours Tuesday and Thursday 12:30-2:30 PM. Include the job ID and submission script ([SLURM and partitions](05-slurm-and-partitions.md)).
- **Group setup problems:** ask the group admin.
