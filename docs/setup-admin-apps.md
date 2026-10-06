# Admin setup: applications

Install procedures for group-wide applications, run by the group admin on a Pegasus login node. Each application is installed read-only under `software/`, described by an Lmod modulefile under `software/modulefiles/`, and used by members through `module load`. Run the commands in order; nothing here is run by members. The general first-time setup is in [First-time admin setup](setup-admin.md).

Items marked **(proposed; confirm)** are decisions that have not been confirmed yet. Replace `<version>` with the real release before running anything, and check each URL on the release page first.

## Miniforge

Miniforge provides `conda` and `mamba` with conda-forge as the default channel and no Anaconda `defaults` channel. This procedure follows the older CBI Miniconda install (download with checksum, batch install, a root `.condarc` for all users, a read-only install, a modulefile), with one change: the modulefile cleans up properly when unloaded, which the CBI module did not.

| Item | Location |
|---|---|
| Install prefix **(proposed; confirm)** | `/GWSPH/groups/bendallgrp/software/miniforge3/<version>` |
| Modulefile **(proposed; confirm)** | `/GWSPH/groups/bendallgrp/software/modulefiles/miniforge3/<version>.lua` |
| Shared environments **(proposed; confirm)** | `/GWSPH/groups/bendallgrp/software/conda/envs` |

### 1. Prepare the directories

`software/` is group-writable, so make the install and modulefile directories owner-writable only. Use `umask 0022` so installed files are readable but not writable by the group.

```bash
umask 0022
G=/GWSPH/groups/bendallgrp
mkdir -p $G/software/miniforge3/archive $G/software/modulefiles/miniforge3
chmod 2755 $G/software/miniforge3 $G/software/modulefiles $G/software/modulefiles/miniforge3
ls -ld $G/software/miniforge3 $G/software/modulefiles
```

### 2. Download and verify the installer

Pick a release at https://github.com/conda-forge/miniforge/releases. Confirm the exact installer and `.sha256` file names on that page; the pattern below is the usual one.

```bash
VER=<version>
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

This is the group's default configuration for everyone who uses this install. Look at what the installer wrote before replacing it (`cat $PREFIX/.condarc`). Contents **(proposed; confirm)**:

```bash
cat > $PREFIX/.condarc <<'EOF'
# System configuration for the Bendall group's Miniforge.
# Personal settings go in ~/.condarc.
channels:
  - conda-forge
  - bioconda
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

Notes:

- No `defaults` channel is configured, which avoids the Anaconda licensing question. Environment YAML files should also list `nodefaults` last, so an environment never pulls `defaults` even if someone's own `~/.condarc` mentions it.
- The CBI file also set `allow_other_channels`; it is dropped here.
- Whether this root file overrides a user's `~/.condarc`, or the other way round, is not confirmed. Test it in step 9.

### 5. Make the install read-only

```bash
chmod -R go-w $PREFIX
touch $PREFIX/conda-meta/frozen        # blocks changes to the base environment; VERIFY that this conda version honors it
ls -ld $PREFIX $PREFIX/.condarc
```

Members must never install into the base environment. Shared environments live in `software/conda/envs` and are created by the admin; personal ones go in `~/.conda/envs`.

### 6. Write the modulefile **(proposed; confirm)**

The CBI module sourced a copy of `conda init`, which could not be undone. This one loads the conda shell functions, exports them so subshells such as a project's `run.sh` see them, and on unload deactivates environments, removes the install from `PATH`, and unsets the functions. `family("conda")` makes Lmod refuse to load it together with any other conda module, such as the RTS `miniconda`.

```bash
cat > $G/software/modulefiles/miniforge3/$VER.lua <<EOF
-- -*- lua -*-
-- Miniforge3 $VER for the Bendall group.
-- Install and maintenance: docs/setup-admin-apps.md in the GWHPC-bendallgrp repository.
local version = "$VER"
local prefix  = pathJoin("/GWSPH/groups/bendallgrp/software/miniforge3", version)
local funcs   = "conda __conda_activate __conda_hashr __conda_reactivate"

whatis("Name: Miniforge3")
whatis("Version: " .. version)
whatis("Description: conda and mamba with conda-forge and bioconda; no Anaconda defaults channel")
help([[
Miniforge3 (conda and mamba). Group defaults come from the .condarc in the install prefix.
Personal environments go in ~/.conda/envs; shared group environments are read-only.
Documentation: docs/setup-admin-apps.md in the GWHPC-bendallgrp repository.
]])

-- Only one conda may be loaded at a time (blocks e.g. the RTS miniconda module).
family("conda")

execute{cmd=". " .. prefix .. "/etc/profile.d/conda.sh; export -f " .. funcs, modeA={"load"}}
execute{cmd="for i in \$(seq \${CONDA_SHLVL:-0}); do conda deactivate; done; "
         .. "export PATH=\$(echo \"\$PATH\" | tr ':' '\\\\n' | grep -v '^" .. prefix .. "' | paste -sd: -); "
         .. "unset -f " .. funcs .. "; "
         .. "unset CONDA_EXE CONDA_PYTHON_EXE CONDA_SHLVL _CE_CONDA _CE_M",
        modeA={"unload"}}
EOF
chmod 644 $G/software/modulefiles/miniforge3/$VER.lua
cat $G/software/modulefiles/miniforge3/$VER.lua    # check the shell escapes came out right
```

Optionally mark one version as the default:

```bash
cat > $G/software/modulefiles/miniforge3/.modulerc.lua <<EOF
module_version("miniforge3/$VER", "default")
EOF
```

### 7. Make the module path available

Members need the modulefile directory on their `MODULEPATH`. The group shell setup adds `module use $G/software/modulefiles` for interactive shells **(proposed; confirm)**. Loading is deliberately opt-in: it injects the `conda` function into the shell and could clash with a member's own conda setup. Members run `module load miniforge3`, or opt in by setting `BENDALLGRP_LOAD_CONDA=1` in `~/.bashrc` before the group block. A project's `run.sh` loads the module explicitly, so workflows never depend on anyone's `.bashrc`. See [Group shell setup](11-shell-setup.md).

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

Then check the family guard: with `miniforge3` loaded, `module load miniconda/23.11.0-2` should be refused or swapped, not stacked.

### 9. Verify `.condarc` precedence

Confirm with a throwaway home directory, so your real `~/.condarc` is untouched:

```bash
module load miniforge3
T=$(mktemp -d)
printf 'channels:\n  - defaults\n' > $T/.condarc
HOME=$T conda config --show channels channel_priority
rm -rf $T
```

If `channels` shows `defaults`, user settings override the root file, and the group defaults cannot be enforced through `.condarc` alone. Record the result here and in [Conda and software](04-conda.md), and consider also setting the channels with `CONDA_CHANNELS` in the modulefile.

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

Never modify an installed version. Repeat steps 2 to 6 with a new `<version>` (new prefix, new modulefile), move the `default` in `.modulerc.lua`, and keep older versions until nothing depends on them.
