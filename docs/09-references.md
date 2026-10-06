# 9. Reference data (genomes, annotations, aligner indexes)

## Design

| Copy | Location | Role |
|---|---|---|
| **Master** | `/GWSPH/groups/bendallgrp/shared_resources/references/refDB` (NFS) | Persistent, authoritative. Built by the [referenceDB](https://github.com/bendall-lab/referenceDB) workflow (its `db_dir`). |
| **Mirror** | `/scratch/bendallgrp/shared/references/refDB` (DSS) | Disposable cache that jobs actually read. Many jobs can read an index at once without loading NFS. |

The `referenceDB` workflow repository lives in `software/workflows/referenceDB`. Its results target is the master. Set its `build_dir` to scratch so build temp files stay off NFS.

Workflows never read the master for large files; they stage a reference into the mirror first and read it from there. Small files (FASTA headers, chrom sizes) are fine from either copy.

## Staging rule

`templates/project/rules/stage_reference.smk` is copied into every new project and included by the Snakefile. It provides:

- `ref_staged("GRCh38")`: marker file; list it as a rule input to trigger staging.
- `ref_path("GRCh38", "star_2.7.11b")`: path inside the mirror.

```python
rule align:
    input:
        staged=ref_staged("GRCh38"),
        fastq="01_raw/{sample}.fq.gz",
    params:
        index=ref_path("GRCh38", "star_2.7.11b"),
    ...
```

`ref` is any path under the refDB root. Mirror and master locations come from `references:` in `config.yaml`.

## Why the sync is written the way it is

- **Purge policy.** Scratch is purged when it fills; the stated threshold is 60 or 90 days (**VERIFY**), likely by access time (**VERIFY** with RTS). A purge removes individual files, so a reference directory can survive partially. A "directory exists" check would miss that, so staging always runs `rsync`, which is cheap when nothing changed and restores whatever is missing.
- **`--size-only`, no `-t`.** Unchanged files are compared by size alone and are not read, so the check itself doesn't touch access times. Copies get the time of copying as their mtime, which also protects them if the purge turns out to use mtime. Files that jobs read refresh their own access time. A reference nobody uses for the whole purge window will vanish and be restored on next use.
- **Index files that change size are fine; same-size content changes are not.** If an index is rebuilt in place with identical file sizes, `--size-only` will not notice. Build new indexes under a new directory name (tool version in the name, as in `star_2.7.11b`) rather than overwriting.
- **`flock`.** Several workflows may stage the same reference at once. Each rsync takes a lock in `/scratch/bendallgrp/shared/references/refDB.locks/`, and the rule and `sync-references.sh` use the same path.
- **`temp()` marker.** The marker disappears after consumers finish, so the next run that needs the reference stages again.
- **SLURM job, not a local rule.** Copying multi-GB indexes happens on a compute node, not the login node.

## Manual sync

```bash
scripts/sync-references.sh --dry-run             # preview
scripts/sync-references.sh GRCh38                # one reference
scripts/sync-references.sh                       # everything
```

A weekly cron job running the last command keeps the mirror warm. **VERIFY** whether cron is available on the Pegasus login nodes.

## Permissions

`shared_resources/references` and `refDB` are group-writable (2775) so any designated builder can run `referenceDB`. Once a reference is built, make it read-only: `chmod -R a-w <ref>`. The mirror is group-writable so any member's job can repair it.
