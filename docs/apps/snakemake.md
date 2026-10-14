# Snakemake (shared conda environment)

- **What it is:** the Snakemake workflow manager, https://snakemake.readthedocs.io, with `snakemake-executor-plugin-slurm`, as in [Snakemake 9+ workflows](../06-snakemake.md)
- **Module:** `snakemake/<version>`
- **Install tree:** `/GWSPH/groups/bendallgrp/software/conda/envs/snakemake-<version>` (a conda environment, created by the admin and read-only for members)
- **Modulefile:** `modulefiles/snakemake/<version>.lua` in this repository, published to `/GWSPH/groups/bendallgrp/software/modulefiles/snakemake/<version>.lua`
- **Maintainer:** group admin

The versions in the committed modulefile (`9.14.0`) and in the commands below are placeholders: **VERIFY** the current Snakemake 9 release on conda-forge (`mamba search -c conda-forge -c bioconda snakemake`) and keep the modulefile name, its `version`, `.modulerc.lua` and the environment name identical.

## Using it

```bash
module load snakemake
snakemake --version
```

The module only puts the environment's `bin/` on `PATH`; it does not activate conda. Projects made by `new-project.sh` call `snakemake` from `run.sh`, so loading the module before `./run.sh` is enough (the job-submitting shell's environment is inherited, as described in [Miniforge3](miniforge3.md) step 7). Workflows still follow the run pattern in [06](../06-snakemake.md): `--directory` on scratch, a profile for the SLURM executor.

Caveats:

- Rules that use `conda:` (per-rule environments) need a `conda`/`mamba` on `PATH`: also `module load miniforge3` (its `bin/` goes ahead of the snakemake environment on `PATH`, so check `which snakemake` still points at the group environment). **VERIFY** whether `snakemake` from conda-forge ships its own `conda`; if it does, this note can go.
- Only one `snakemake/*` version can be loaded at a time (`family("snakemake")`).
- Members cannot install into the environment. For extra Python packages in a workflow, use per-rule environments or ask the admin for a new version.

## Install <version>

Run on a Pegasus login node as the admin. Nothing here is run by members. Needs the [Miniforge3](miniforge3.md) module (this is its step 10).

```bash
umask 0022
G=/GWSPH/groups/bendallgrp
SMK="9.14.0"                      # VERIFY: current Snakemake 9 release
module use $G/software/modulefiles
module load miniforge3

mamba create -p $G/software/conda/envs/snakemake-$SMK \
    -c conda-forge -c bioconda --override-channels \
    snakemake=$SMK snakemake-executor-plugin-slurm
```

`--override-channels` keeps the Anaconda `defaults` channel out regardless of anyone's `.condarc`. Make it read-only for members, then check it works without conda activation (this is how the module uses it):

```bash
chmod -R go-w $G/software/conda/envs/snakemake-$SMK
$G/software/conda/envs/snakemake-$SMK/bin/snakemake --version
$G/software/conda/envs/snakemake-$SMK/bin/snakemake --help | grep -i executor
```

Record the exact package set. The YAML is committed so the environment can be rebuilt:

```bash
conda env export -p $G/software/conda/envs/snakemake-$SMK --no-builds \
    > ~/snakemake-$SMK.yaml
```

Copy that file into the repository on your workstation as `envs/snakemake-<version>.yaml`, commit it, and delete the copy in your home directory; do not leave uncommitted files in the cluster checkout.

## Modulefile

Committed as `modulefiles/snakemake/<version>.lua` (and `.modulerc.lua` for the default), then published:

```bash
cd $G/software/tools/GWHPC-bendallgrp.git && git pull
scripts/install-modulefiles.sh --dry-run
scripts/install-modulefiles.sh
```

## Verify

```bash
module use $G/software/modulefiles
module avail snakemake
module load snakemake
which snakemake && snakemake --version
module help snakemake
module unload snakemake
which snakemake                  # should no longer be the group environment
```

Then run a project dry run: `./run.sh -n` in a project created by `new-project.sh`.

## Upgrading

Never modify an installed environment. Create `snakemake-<new>` as above, copy `modulefiles/snakemake/<old>.lua` to `<new>.lua`, change `version`, move the default in `.modulerc.lua`, commit, pull on the cluster and publish. Keep older versions until nothing depends on them.

## Changelog

| Date | Version | Change |
|---|---|---|
| YYYY-MM-DD | <version> | initial install |
