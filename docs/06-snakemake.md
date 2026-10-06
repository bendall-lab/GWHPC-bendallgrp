# 6. Snakemake 9+ workflows

New workflows use **profiles** with `snakemake-executor-plugin-slurm`. `cluster.yaml` and `--cluster` are not supported in Snakemake 8+.

```bash
mamba create -n snakemake -c conda-forge -c bioconda snakemake snakemake-executor-plugin-slurm
```

## Run pattern

Code and profile are on NFS. The **working directory is on scratch**, so `.snakemake/` (locks, metadata) and all relative-path intermediates land on DSS. Only final results are written to absolute paths on NFS.

```bash
snakemake --snakefile $PROJECT/Snakefile \
          --directory /scratch/bendallgrp/users/$USER/<project> \
          --workflow-profile $PROJECT/profiles/slurm
```

`run.sh` in each project does exactly this. Note that `--shadow-prefix` only controls where `shadow:` rules run; it does not move `.snakemake/`, so use `--directory` for that.

Snakemake itself must keep running while jobs are in the queue. Start it in `tmux`/`screen` on a login node or inside a small `sbatch` job.

## The profile

See `templates/project/profiles/slurm/config.yaml`. Key points:

- `slurm_partition`, `runtime` (minutes), `mem_mb`, `cpus_per_task` are the plugin's resource names. Set defaults under `default-resources` and per-rule overrides under `set-resources`.
- `latency-wait: 60` covers file-visibility lag between nodes.
- No `slurm_account` is set because none is required.
- GPU rules need `slurm_partition: gpu` plus `slurm_extra: "'--gres=gpu:<TYPE>:1'"`.

## Local scratch

`resources.tmpdir` defaults to `$TMPDIR` inside the job. Once `scripts/check-node-storage.sh` confirms the node-local path, either set `tmpdir` in the profile or pass `-T {resources.tmpdir}/...` to tools like `samtools sort`. Keep large temp files off NFS and DSS.

## Migrating from `cluster.yaml`

| `cluster.yaml` | Profile (`default-resources` / `set-resources`) |
|---|---|
| `partition` | `slurm_partition` |
| `time` | `runtime` (minutes) |
| `mem` | `mem_mb` |
| `cpus-per-task` / `ncpus` | `cpus_per_task`, or the rule's `threads:` |
| `__default__` block | `default-resources` |
| per-rule block | `set-resources: <rule>:` |
| `--cluster "sbatch ..."` | `executor: slurm` |
| anything else (`--gres`, `--constraint`) | `slurm_extra: "'--flag=value'"` |

Move absolute paths and per-user values from the old `Snakefile`/`config` into `config.yaml`, and make intermediate paths relative so they follow `--directory`.

**VERIFY** each migrated pipeline with `./run.sh -n` (dry run), then a small real run.
