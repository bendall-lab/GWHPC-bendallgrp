# 7. Starting a new project

All scripts live in `scripts/`. They accept `-n`/`--dry-run` and the environment overrides `GROUP_ROOT`, `SCRATCH_ROOT`, and `UNIX_GROUP`.

| Script | Who runs it | What it does |
|---|---|---|
| `init-group-dir.sh` | group admin, once | creates the group and scratch layout with group ownership and setgid |
| `user-map.sh add\|lookup\|list` | group admin | maintains the Linux username to handle map ([details](10-user-names.md)) |
| `init-user.sh [linux_user]` | each new member (after being added to the map) | creates `users/<handle>` and the `.<linux_user>` link on NFS and scratch |
| `new-project.sh NAME` | any member | copies `templates/project/` to `projects/NAME`, fills in paths, creates the scratch workdir |
| `check-node-storage.sh` | anyone, on a compute node | reports storage tiers visible from the node |
| `sync-references.sh [REF...]` | anyone, on Pegasus | syncs refDB from NFS master to the scratch mirror ([details](09-references.md)) |

## Workflow

```bash
git clone <this repo> ~/hpc-docs && cd ~/hpc-docs

scripts/user-map.sh add $USER <handle> "<Full Name>"   # once per member (or ask the admin)
scripts/init-user.sh                 # once per member
scripts/new-project.sh 2026_rnaseq   # per project

cd /GWSPH/groups/bendallgrp/projects/2026_rnaseq
git init                             # project code is its own repository
./run.sh -n                          # dry run
./run.sh                             # run
```

## Setting up the group (first time)

```bash
scripts/init-group-dir.sh --dry-run   # review
scripts/init-group-dir.sh
```

The template's example rules only count lines in `01_raw/<sample>.txt`; replace them with real steps.
