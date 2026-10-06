# @PROJECT_NAME@

- **Question / goal:**
- **Owner:**
- **Data origin (accessions, sequencing run):**

## Layout

| Path | Contents |
|---|---|
| `Snakefile`, `config.yaml` | workflow (NFS, version with git) |
| `profiles/slurm/` | Snakemake 9+ SLURM profile |
| `envs/` | conda env definitions for rules |
| `docs/` | sample sheets, metadata, notes |
| `results/` | final tables/figures only (NFS) |
| `run.sh` | launches Snakemake with workdir on scratch |

Heavy data and intermediates live in `@SCRATCH_ROOT@/users/<handle>/@PROJECT_NAME@/` (also reachable as `users/.<linux_user>/...`).

## Run

```bash
./run.sh -n     # dry run
./run.sh        # submit to SLURM
```
