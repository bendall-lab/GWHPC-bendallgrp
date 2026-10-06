# 10. Usernames and handles

Pegasus usernames are assigned and carry no meaning. The group maps each Linux username to a human-readable **handle** and names user directories by handle.

## The map

`/GWSPH/groups/bendallgrp/admin/user_map.tsv`: tab-separated, one member per line.

```text
# linux_user	handle	full_name	added
u0000001	jane-doe	Jane Doe	2026-01-01
```

- **Stored on the cluster only.** It is not in this repository, so names don't end up in a public GitHub Pages site. `templates/user_map.example.tsv` shows the format.
- `admin/` is group-only (2770), so only members can read it.
- Handles are lowercase letters, digits, `_` and `-`, and unique. Linux usernames are unique too.

```bash
scripts/user-map.sh add u0000001 jane-doe "Jane Doe"
scripts/user-map.sh lookup jane-doe      # -> u0000001
scripts/user-map.sh lookup u0000001      # -> jane-doe
scripts/user-map.sh list
```

## Directory convention

```text
users/jane-doe/        real directory
users/.u0000001  ->  jane-doe            dot-link named after the Linux username
```

The same pair exists under `/scratch/bendallgrp/users/`. Scripts and templates use the dot-link (`users/.$USER`), so they work without a map lookup. `scripts/init-user.sh` creates both the directory and the link on NFS and scratch. It refuses to run for a user who isn't in the map yet.

## Readable `ls` and `squeue`

`scripts/hpc-aliases.sh` provides output filters. Source it from `~/.bashrc` (clone this repo to `software/workflows/GWHPC-bendallgrp` so everyone shares one copy):

```bash
source /GWSPH/groups/bendallgrp/software/workflows/GWHPC-bendallgrp/scripts/hpc-aliases.sh
```

| Function | Use |
|---|---|
| `lsh [args]` | `ls -l` with owner/group names mapped |
| `sqh [args]` | `squeue` with usernames mapped |
| `hpc_filter` | stdin filter; works with any command, e.g. `sacct ... \| hpc_filter` |
| `hpc_whoami` | your handle |

Only whole tokens that equal a Linux username are replaced, so dot-links and handles in paths are untouched. A longer handle shifts columns slightly. The wrappers only change what you see; files keep their real owners.

## New member checklist

1. RTS adds them to the Unix group ([permissions](03-permissions.md)).
2. `scripts/user-map.sh add <linux_user> <handle> "<Full Name>"`
3. The member runs `scripts/init-user.sh` themselves, so the directories are owned by them.
4. The member adds `umask 002` and the `source ...hpc-aliases.sh` line to `~/.bashrc`.
