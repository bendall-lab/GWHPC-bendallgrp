# 4. Conda and software

## Shared environments

Production environments live in `software/conda/envs/` (mode 2755: everyone reads, maintainers write). One or two designated maintainers create and update them; other members activate by path:

```bash
conda activate /GWSPH/groups/bendallgrp/software/conda/envs/rnaseq-v1
```

Version environments by name (`rnaseq-v1`, `rnaseq-v2`) rather than modifying them in place, so past analyses stay reproducible. Export the definition into the relevant project's `envs/` when a paper depends on it:

```bash
conda env export --no-builds -p <env path> > envs/rnaseq-v1.yaml
```

## Snakemake environments

Snakemake builds per-rule environments from `envs/*.yaml`. The profile points `conda-prefix` at `software/conda/snakemake_envs/` so each distinct environment is built once for the whole group instead of once per project.

## Package caches and inodes

Conda caches and environments contain very many small files, which counts against inode quotas and is slow on NFS.

- **VERIFY** the inode limits on the group directory and home directories.
- A per-user package cache in the user's own directory avoids permission and locking conflicts between members; a single shared writable cache is convenient but riskier with concurrent installs. Decide and record here:

```yaml
# ~/.condarc (per user)
pkgs_dirs:
  - /GWSPH/groups/bendallgrp/users/.$USER/conda_pkgs
```

- Prefer `mamba`/`micromamba` for solving. Use `conda-forge` and `bioconda` channels with strict priority.
