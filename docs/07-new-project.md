# 7. Starting a new project

All scripts live in `scripts/`. They accept `-n`/`--dry-run` and the environment overrides `GROUP_ROOT`, `SCRATCH_ROOT`, and `UNIX_GROUP`.

| Script | Who runs it | What it does |
|---|---|---|
| `init-group-dir.sh` | group admin, once | creates the group and scratch layout (group inherited via setgid) |
| `link-local.sh` | group admin | symlinks the user-facing scripts into `local/bin` and `local/etc` |
| `user-map-add.sh` | group admin | adds a member to the Linux username to handle map; not linked into `local/bin` ([details](10-user-names.md)) |
| `init-user.sh [linux_user]` | each new member (after being added to the map) | creates `users/<handle>` and the `.<linux_user>` link on NFS and scratch |
| `new-project.sh NAME` | any member | copies `templates/project/` to `projects/NAME`, fills in paths, creates the scratch workdir |
| `install-shell-setup.sh` | each new member | adds the group shell setup to `~/.bashrc` ([details](11-shell-setup.md)) |
| `check-node-storage.sh` | anyone, on a compute node | reports storage tiers visible from the node |
| `sync-references.sh [REF...]` | anyone, on Pegasus | syncs refDB from NFS master to the scratch mirror ([details](09-references.md)) |

## Where this repo lives on the cluster

The permanent checkout is `/GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git` (on NFS, not scratch, which is purged). The group admin owns it and runs `git pull`; members never write there. Members use the scripts through symlinks in `local/bin/` ([why `local/`](02-directory-layout.md#local-vs-software)), so a `git pull` updates what everyone runs, with no separate deploy step.

First-time setup, and what to run after adding a script, is in [First-time admin setup](setup-admin.md).

## Workflow

```bash
# with local/bin on your PATH (see the shell setup doc):
init-user.sh                         # once per member
new-project.sh 2026_rnaseq           # per project

cd /GWSPH/groups/bendallgrp/projects/2026_rnaseq
git init                             # project code is its own repository
./run.sh -n                          # dry run
./run.sh                             # run
```

The template's example rules only count lines in `01_raw/<sample>.txt`; replace them with real steps.
