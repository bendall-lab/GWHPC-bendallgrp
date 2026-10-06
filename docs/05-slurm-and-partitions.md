# 5. SLURM and partitions

Source: *Pegasus Researcher Guide to Resource Allocation*, Rev B, updated 2026-02-27 (copy in the repo root). Pegasus moved to TRES scheduling on 2026-02-07. Re-check the guide and `sinfo` for changes, since the guide describes a transition period that has since ended.

## Partitions

| Partition | Purpose |
|---|---|
| `cpu` | non-GPU jobs |
| `gpu` | all GPU jobs |
| `longJob` | jobs up to 42 days |
| `viz` | visualization |
| `aws` | cloud burst / burst buffers |
| `basestar` | Grace Hopper nodes |

Legacy partitions were scheduled to retire 2026-05-09. This group has no SLURM account requirement (`--account` not needed, **VERIFY** if submission is rejected).

## Rules that changed

- **Memory is enforced** (cgroups v2). Unrequested memory defaults to 4 GB per CPU core. This is DRAM, not GPU VRAM. Always request `--mem` explicitly.
- **GPUs must be requested explicitly**: `--partition=gpu --gres=gpu:<TYPE>:N`. Find `<TYPE>` with `sinfo -o "%P %G"`.
- **CPU, memory, and GPU requests are enforced as written.** `--exclusive` requests a whole node.
- Always state `--partition=cpu` for CPU jobs until you confirm that the default works.

## Templates

```bash
# CPU job
#SBATCH --partition=cpu --time=0-01:00:00 --cpus-per-task=4 --mem=8G

# GPU job
#SBATCH --partition=gpu --gres=gpu:<TYPE>:1 --cpus-per-gpu=4 --mem-per-gpu=32G --time=0-01:00:00
```

## Debugging a failed job

```bash
sacct -X -j <jobid> -o ReqTRES%50,AllocTRES%50
```

Compare requested to allocated resources, then check the `.out`/`.err` files. Support: rtshelp@gwu.edu, office hours Tue/Thu 12:30-2:30 PM.
