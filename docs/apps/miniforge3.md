# Miniforge3 (conda and mamba)

Install procedure for the group-wide Miniforge, run by the group admin on a Pegasus login node. It is 
installed read-only under `software/`, described by an Lmod modulefile under `software/modulefiles/`, and used by 
members through `module load`. Run the commands in order; nothing here is run by members. The general first-time setup
is in [First-time admin setup](../setup-admin.md).

Replace `<version>` with the real release before running anything, and check each URL on the release page first.

Miniforge provides `conda` and `mamba` with conda-forge as the default channel and no Anaconda `defaults` channel. 
This procedure follows the older CBI Miniconda install (download with checksum, batch install, a root `.condarc` for 
all users, a read-only install, a modulefile), with one change: the modulefile cleans up properly when unloaded, which
the CBI module did not.

| Item | Location |
|---|---|
| Install prefix  | `/GWSPH/groups/bendallgrp/software/miniforge3/<version>` |
| Modulefile  | `/GWSPH/groups/bendallgrp/software/modulefiles/miniforge3/<version>.lua` |
| Shared environments  | `/GWSPH/groups/bendallgrp/software/conda/envs` |

### 1. Prepare the directories

`software/` is group-writable, so make the install and modulefile directories owner-writable only. Use `umask 0022` so 
installed files are readable but not writable by the group.

```bash
umask 0022
G=/GWSPH/groups/bendallgrp
mkdir -p $G/software/miniforge3/archive $G/software/modulefiles/miniforge3
chmod 2755 $G/software/miniforge3 $G/software/modulefiles $G/software/modulefiles/miniforge3
ls -ld $G/software/miniforge3 $G/software/modulefiles
```

### 2. Download and verify the installer

Pick a release at https://github.com/conda-forge/miniforge/releases. 

```bash
VER="26.7.2-0"  # Latest release as of 2026-OCT-06
```

Confirm the exact installer and `.sha256` file names on that page; the pattern below is the usual one.

```bash
cd $G/software/miniforge3/archive
wget https://github.com/conda-forge/miniforge/releases/download/$VER/Miniforge3-$VER-Linux-x86_64.sh
wget https://github.com/conda-forge/miniforge/releases/download/$VER/Miniforge3-$VER-Linux-x86_64.sh.sha256
sha256sum -c Miniforge3-$VER-Linux-x86_64.sh.sha256      # must print: ...: OK
```

### 3. Install

`-b` runs in batch mode and does not touch any `~/.bashrc`; `-p` sets the prefix.

```bash
PREFIX=$G/software/miniforge3/$VER
bash $G/software/miniforge3/archive/Miniforge3-$VER-Linux-x86_64.sh -b -p $PREFIX
$PREFIX/bin/conda --version
```

### 4. Write the root `.condarc`

This is the group's default configuration for everyone who uses this install. Look at what the installer 
wrote before replacing it (`cat $PREFIX/.condarc`). Contents **(proposed; confirm)**:

```bash
cat > $PREFIX/.condarc <<'EOF'
# System configuration for the Bendall group's Miniforge.
# Personal settings go in ~/.condarc.
channels:
  - conda-forge
  - bioconda
  - nodefaults
mirrored_channels:
  conda-forge:
    - https://conda.anaconda.org/conda-forge
    - https://prefix.dev/conda-forge
channel_priority: strict
auto_update_conda: False
notify_outdated_conda: False
auto_activate_base: False
# Named environments are created in the first writable directory.
envs_dirs:
  - ~/.conda/envs
  - /GWSPH/groups/bendallgrp/software/conda/envs
pkgs_dirs:
  - ~/.conda/pkgs
EOF
```

Note: Including `nodefaults` here which avoids the Anaconda licensing question. An environment YAML file or 
user `~/.condarc` may override this by including `defaults`; user is responsible for checking licenses. _(unconfirmed)_

### 5. Make the install read-only

```bash
find "$PREFIX" -type d ! -perm 755 -exec chmod 755 {} +
find "$PREFIX" -type f ! -perm /111 ! -perm 644 -exec chmod 644 {} +
find "$PREFIX" -type f -perm /111 ! -perm 755 -exec chmod 755 {} +
```
Block changes to the base environment with `conda-meta/frozen`

```
echo '{"message": "base environment for bendallgrp is locked."}' > $PREFIX/conda-meta/frozen
ls -ld $PREFIX $PREFIX/.condarc
```

Members must never install into the base environment. Shared environments live in `software/conda/envs` and are created
by the admin; personal ones go in `~/.conda/envs`.

### 6. Install the modulefile

Modulefiles are committed in this repository, not written by a heredoc: `modulefiles/miniforge3/<version>.lua` and `modulefiles/miniforge3/.modulerc.lua`. `scripts/install-modulefiles.sh` **copies** them (it does not symlink them) to `$G/software/modulefiles/`, so a `git pull` or a branch switch in the checkout can never change or break `module load` for members; published modulefiles change only when you run the script.

What the modulefile does: it loads the conda shell functions and exports them (so subshells such as a project's `run.sh` see them), and on unload it deactivates environments, removes the install from `PATH` and unsets the functions. `family("python")` and `conflict("anaconda", "miniconda", "miniconda3")` keep it from being loaded alongside another conda or Python module such as the RTS `miniconda`. `.modulerc.lua` marks the default version.

Limit of `conflict()`: it only stops this module from loading while one of the listed modules is already loaded. It cannot stop someone loading, say, an RTS `anaconda/*` module afterwards, because only that module could declare the conflict, and the RTS modules are not ours to edit. The RTS `miniconda` module sets `family("python")` like ours, so Lmod handles that pair. Modules with no family can still end up loaded together, with `PATH` order following load order. To check, load an RTS `anaconda/*` module after ours and look at `which python` and `$CONDA_PREFIX`.

On load it also runs `conda activate base`, so conda's own `(base)` prompt prefix shows that the module is loaded; unloading deactivates it and restores the prompt. This puts the Miniforge `bin` directory ahead of the system tools on `PATH` for as long as the module is loaded, and a prompt tool that rebuilds `PS1` on every prompt (starship, some Oh My Bash themes) will not show the prefix; for those, run `conda config --set changeps1 false` and let the tool read `CONDA_DEFAULT_ENV`. `auto_activate_base: False` in the `.condarc` stays as is: it only governs the activation done by a `conda init` block in someone's `~/.bashrc`, which this module does not use. What the module itself activates is decided only by the `execute{...}` lines in the modulefile (without the `conda activate base` line, loading the module defines `conda` but activates nothing).

Test after publishing: `module load miniforge3; echo "$PS1"; conda env list; module unload miniforge3; echo "$PS1"`.

```bash
cd $G/software/tools/GWHPC-bendallgrp.git
git pull
scripts/install-modulefiles.sh --dry-run     # lists changes and shows a diff
scripts/install-modulefiles.sh
cat $G/software/modulefiles/miniforge3/$VER.lua
```

The script never deletes published modulefiles unless you pass `--delete`.

### 7. Make the module path available

The group shell setup (`scripts/group-bashrc.sh`) runs `module use $G/software/modulefiles` for interactive shells, so members see the group's modules in `module avail`. Loading is deliberately opt-in, because it injects the `conda` function and an active base environment into the shell and could clash with a member's own conda setup. Members run `module load miniforge3`, or opt in for every interactive shell by setting `BENDALLGRP_LOAD_CONDA=1` in `~/.bashrc` before the group block. See [Group shell setup](../11-shell-setup.md).

Batch jobs and scripts do not run the group bashrc. They inherit `MODULEPATH` and the loaded modules from the shell that submitted them. A project's `run.sh` loading the module itself is planned but not implemented yet; it waits on the Snakemake module (step 10).

### 8. Verify

```bash
module use $G/software/modulefiles
module avail miniforge3
module load miniforge3
conda --version && mamba --version
conda config --show channels channel_priority envs_dirs pkgs_dirs
conda env list
module unload miniforge3
type conda                      # should now report: not found
```

Then check the family guard: with `miniforge3` loaded, `module load miniconda/23.11.0-2` should be refused or swapped, 
not stacked.

### 9. Verify `.condarc` precedence



```bash
module load miniforge3
[[ -e ~/.condarc ]] && OC=$(mktemp) && cat ~/.condarc > $OC
printf 'channels:\n  - defaults\n' > ~/.condarc
conda config --show channels channel_priority
rm -f ~/.condarc
[[ -n "${OC+x}" ]] && cat $OC > ~/.condarc && rm $OC
```

See that "defaults" is at the top of the channels list, therefore, user settings override the root file. 
[Conda and software](../04-conda.md), and consider also setting the 
channels with `CONDA_CHANNELS` in the modulefile.

### 10. Shared Snakemake 9 environment (later step)

Create the environment with the group install, owned by you and read-only for members. Replace the version placeholder.

```bash
module load miniforge3
conda create -p $G/software/conda/envs/snakemake-<snakemake_version> \
    -c conda-forge -c bioconda --override-channels \
    snakemake=<snakemake_version> snakemake-executor-plugin-slurm
chmod -R go-w $G/software/conda/envs/snakemake-<snakemake_version>
conda env export -p $G/software/conda/envs/snakemake-<snakemake_version> --no-builds
```

Keep the exported YAML in this repository so the environment can be rebuilt. A `bendallgrp/snakemake/<snakemake_version>` module that loads `miniforge3` and activates this environment is the next step and is not written yet.

## Upgrading or adding a version

Never modify an installed version. Repeat steps 2 to 5 with the new `<version>` (new prefix), then in the repository:

1. Copy `modulefiles/miniforge3/<old>.lua` to `modulefiles/miniforge3/<new>.lua` and change `local version`.
2. Move the default in `modulefiles/miniforge3/.modulerc.lua`.
3. Commit and push, then on the cluster `git pull` and run `scripts/install-modulefiles.sh` (step 6).

Keep older versions until nothing depends on them.
