# 5. SLURM and partitions

Sources: the *Pegasus Researcher Guide to Resource Allocation*, Rev B, updated 2026-02-27 (copy in the repo root), and live `sinfo` output captured on 2026-10-06. **The guide is out of date for partitions**; trust `sinfo`, and re-check it from time to time. Pegasus moved to TRES scheduling on 2026-02-07.

## Partitions

Snapshot from `sinfo -s` on 2026-10-06 (the partitions a regular user sees):

| Partition | Time limit | Nodes | Notes |
|---|---|---|---|
| `cpu` (default) | 14 days | 153 | all non-GPU jobs; the default partition, so `--partition` can be omitted |
| `gpu` | 7 days | 40 | all GPU jobs; GPU types `v100` (several node shapes) and `a100` (8 per node, 2 nodes) |
| `superChip` | 7 days | 8 | Grace Hopper, `gh200` (1 GPU per node); the guide calls this `basestar` |
| `viz` | 7 days | 2 | visualization; `l40s` GPUs (2 per node) |
| `nano` | 30 minutes | 4 | very short jobs; the only short-limit partition left, so the choice for quick tests now that `debug` is gone |
| `deus` | unlimited | 2 | purpose unknown; both nodes were down in the snapshot |

`sinfo -a` also lists partitions that were hidden from this account: `highMemInt` (one node, 14 days), `purge`, `secret`, and several cloud partitions (`awscpu`, `awsgpu`, `awsg6e12xl`, `awsg6e4xl`, `awsr7a48xl`, limits of 6 hours to 1 day, nodes that start on demand). Whether a group member can use them depends on the partition's access rules; run `sinfo -s` as a member to see what they get.

Not present any more: `debug`, `longJob` (the guide's 42-day partition), `basestar`, and the old `aws` partition. The longest limit available to a regular user is therefore 14 days on `cpu`; anything longer needs a workflow that checkpoints and resubmits, or a request to RTS.

Check the current layout yourself:

```bash
sinfo -s                      # partitions you can see, with node counts
sinfo -o "%P %G %l"           # partition, GPU types, time limit
```

Slurm accounting enforces associations, so every user needs an account association even though `--account` is not normally typed. Some members are associated with the `cbi` account and the rest with `bendallgrp`; `sacctmgr show assoc user=$USER format=user,account` shows yours. See [First-time admin setup](setup-admin.md).

## Rules that changed

- **Memory is enforced** (cgroups v2). Unrequested memory defaults to 4 GB per CPU core. This is DRAM, not GPU VRAM. Always request `--mem` explicitly.
- **GPUs must be requested explicitly**: `--partition=gpu --gres=gpu:<TYPE>:N`. Find `<TYPE>` with `sinfo -o "%P %G"`.
- **CPU, memory, and GPU requests are enforced as written.** `--exclusive` requests a whole node.
- `cpu` is the default partition (marked `*` in `sinfo`), so CPU jobs need no `--partition`. GPU jobs must request `--partition=gpu` (or `superChip`/`viz` for those GPUs) and `--gres`.

## Templates

```bash
# CPU job (--partition=cpu is optional; it is the default)
#SBATCH --partition=cpu --time=0-01:00:00 --cpus-per-task=4 --mem=8G

# GPU job; <TYPE> is v100 or a100 on gpu (gh200 on superChip, l40s on viz)
#SBATCH --partition=gpu --gres=gpu:<TYPE>:1 --cpus-per-gpu=4 --mem-per-gpu=32G --time=0-01:00:00

# Quick test (30-minute limit)
#SBATCH --partition=nano --time=0-00:10:00 --cpus-per-task=2 --mem=4G
```

## Debugging a failed job

```bash
sacct -X -j <jobid> -o ReqTRES%50,AllocTRES%50
```

Compare requested to allocated resources, then check the `.out`/`.err` files. Support: hpchelp@gwu.edu (rtshelp@gwu.edu, which the Rev B guide gives, reaches the same ticketing system). Office hours Tue/Thu 12:30-2:30 PM.
