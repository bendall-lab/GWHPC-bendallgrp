# Snakemake (shared pixi environment)

- **What it is:** the Snakemake workflow manager, https://snakemake.readthedocs.io, with `snakemake-executor-plugin-slurm`, storage plugins (see [Plugins](#plugins)), `conda` and `mamba`, as in [Snakemake 9+ workflows](../06-snakemake.md). Snakemake's documentation recommends installing it with [pixi](pixi.md), so the install is a locked pixi project.
- **Module:** `snakemake/<version>`
- **Install tree:** `/GWSPH/groups/bendallgrp/software/snakemake/<version>/` (`pixi.toml`, `pixi.lock`, and the environment in `.pixi/envs/default`); read-only for members
- **Recipe in this repository:** `envs/snakemake/<version>/pixi.toml` and `pixi.lock`
- **Modulefile:** `modulefiles/snakemake/<version>.lua`, published to `/GWSPH/groups/bendallgrp/software/modulefiles/snakemake/<version>.lua`
- **Maintainer:** group admin

## Using it

```bash
module load snakemake
snakemake --version
```

The module puts the environment's `bin/` on `PATH`; it does not activate anything and members never run `pixi`. Projects from `new-project.sh` call `snakemake` in `run.sh`, so load the module before `./run.sh`; the job-submitting shell's environment is inherited ([Miniforge3](miniforge3.md) step 7). Workflows follow the run pattern in [06](../06-snakemake.md).

**The `conda:` directive.** The environment contains `conda` and `mamba`, which is what Snakemake calls to build per-rule environments (`--software-deployment-method conda`, with `conda-prefix` set by the project profile). No `miniforge3` module is needed. Also loading `miniforge3` is allowed; whichever was loaded last supplies `conda`. The environment's root `.condarc` (see install) gives the same channels as Miniforge, with `nodefaults`. **VERIFY** this on the cluster with the test workflow below before announcing the module.

Caveats:

- Only one `snakemake/*` version can be loaded at a time (`family("snakemake")`).
- The base environment is read-only. Rule environments are created by Snakemake under `conda-prefix`, not inside it; packages are cached per user in `~/.conda/pkgs`.
- To add Python packages for a workflow, use per-rule environments, or ask the admin for a new version.
- The versions are pinned. 9.27.0 was current when this was written; workflows developed on 9.17.3 should run unchanged, but check the Snakemake changelog if a rule behaves differently. Older versions can be installed side by side (see Upgrading).

## Plugins

Included in the shared environment:

| Kind | Plugins |
|---|---|
| Executor | `slurm` (it brings `slurm-jobstep`) |
| Storage | `http`, `cached-http`, `s3`, `gcs`, `zenodo`, `fs` |
| Tool | `rclone` binary |

Why the extras: `cached-http` keeps a shared download cache, so a file fetched by one member is not fetched again; `fs` gives remote-file semantics for a shared filesystem. **There is no `rclone` storage plugin on conda-forge or bioconda** (nor on PyPI as of 2026-10), so `rclone` is only the command-line tool for use in rules or by hand. Not included: `sftp` (its `pysftp` dependency fails to import with current `paramiko`, which breaks Snakemake at startup), `azure`, `ftp`, `irods`, `rucio`, `xrootd`, `sharepoint` (request them if needed) and the logger plugins `panoptes`, `snkmt` and `prometheus`, which need a server to report to.

**One broken plugin breaks Snakemake.** Snakemake imports every installed plugin when it starts, so the set is kept small and each addition must pass `snakemake --version` after the install.

**Report plugins** (`snakemake-report-plugin-fairscape`, `-nanopub`) are not on conda channels and are PyPI-only. A trial solve with both added resolved, but added about a dozen PyPI packages (rdflib, pyshacl, nanopub and others) and moved Python from 3.14 to 3.13. They are 0.1.0 and 0.3.2 releases that only act when you pass a report plugin option. Not harmful, but not worth coupling every user's Snakemake to. Keep them out of the group environment and put them in the workflow's own `pixi.toml` (below) for the projects that use them.

**Can members add plugins to the group module?** Not into the environment: it is read-only, and that is intended. Snakemake finds plugins by importing installed `snakemake_*_plugin_*` Python packages, so a plugin placed on `PYTHONPATH` (for example `pip install --target ~/snk-plugins <plugin>` and `export PYTHONPATH=~/snk-plugins`) should be discovered. **VERIFY**, and expect trouble when the plugin's dependency pins disagree with the environment's. Prefer the next option.

**Recommended for anything beyond the shared set: the workflow's own `pixi.toml`.** A project with a `pixi.toml` and committed `pixi.lock` pins its own Snakemake and plugins (conda or PyPI), rebuilds identically for any member, and does not depend on which group version is installed. Run it with `pixi run snakemake ...` from the project (after `module load pixi`). The group `snakemake` module then remains the easy default for quick work. `new-project.sh` projects already do this: the template has a `pixi.toml`/`pixi.lock` and `run.sh` uses them ([details](../07-new-project.md#project-software-pixi)).

## Install <version>

Run on a Pegasus login node as the admin. Nothing here is run by members. Needs the [pixi](pixi.md) module.

```bash
umask 0022
G=/GWSPH/groups/bendallgrp
SMK="9.27.0"
module use $G/software/modulefiles
module load pixi

cd $G/software/tools/GWHPC-bendallgrp.git && git pull
mkdir -p $G/software/snakemake/$SMK
cp envs/snakemake/$SMK/pixi.toml envs/snakemake/$SMK/pixi.lock $G/software/snakemake/$SMK/
cd $G/software/snakemake/$SMK
pixi install --locked
```

`--locked` installs exactly the committed `pixi.lock` and fails if it does not match `pixi.toml`. The environment has to be created at its final location because paths are baked into it; do not move it afterwards. Pixi caches downloads in `~/.cache/rattler` (set `PIXI_CACHE_DIR` if your home is small).

Write the root `.condarc` for the environment's `conda` (same intent as [Miniforge3](miniforge3.md) step 4):

```bash
ENVDIR=$G/software/snakemake/$SMK/.pixi/envs/default
cat > $ENVDIR/.condarc <<'EOC'
# System configuration for conda inside the Bendall group's Snakemake environment.
channels:
  - conda-forge
  - bioconda
  - nodefaults
channel_priority: strict
auto_update_conda: False
notify_outdated_conda: False
pkgs_dirs:
  - ~/.conda/pkgs
EOC
chmod -R go-w $G/software/snakemake/$SMK
```

Check it works without any activation, which is how the module uses it:

```bash
$ENVDIR/bin/snakemake --version
$ENVDIR/bin/snakemake --help | grep -i executor
$ENVDIR/bin/conda --version && $ENVDIR/bin/mamba --version
$ENVDIR/bin/conda config --show channels channel_priority pkgs_dirs
```

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
which snakemake conda && snakemake --version
module help snakemake
```

Then the check that matters, as a **member** (not the admin), because it is the part not tested when this page was written. A workflow with a `conda:` rule:

```bash
T=$(mktemp -d) && cd $T && mkdir envs
cat > envs/hello.yaml <<'EOY'
channels: [conda-forge, nodefaults]
dependencies: [python=3.12]
EOY
cat > Snakefile <<'EOS'
rule all:
    input: "out.txt"
rule hello:
    output: "out.txt"
    conda: "envs/hello.yaml"
    shell: "python --version > {output}"
EOS
snakemake --cores 1 --software-deployment-method conda --conda-prefix $T/conda
cat out.txt; cd; rm -rf $T
```

It should create the environment, run the rule and print `Python 3.12.x`. Then run a project dry run (`./run.sh -n`) and a small real run through the SLURM profile, where `conda-prefix` points at `software/conda/snakemake_envs`. If conda fails in the first test, check `which conda`, `conda info`, and whether `~/.conda` is writable.

## Upgrading

Never modify an installed environment. For a new version: copy `envs/snakemake/<old>` to `<new>`, change the pin in `pixi.toml`, run `pixi lock` in that directory (any machine with pixi; `platforms` is `linux-64`) and commit both files. Copy `modulefiles/snakemake/<old>.lua` to `<new>.lua`, change `version`, move the default in `.modulerc.lua`, commit, then repeat the install on the cluster. Keep older versions until nothing depends on them; a project that needs 9.17.3 can have that as its own entry.

## Changelog

| Date | Version | Change |
|---|---|---|
| YYYY-MM-DD | 9.27.0 | initial install (pixi) |
