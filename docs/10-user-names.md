# 10. Usernames and handles

Pegasus usernames are assigned and carry no meaning. The group maps each Linux username to a human-readable **handle** and names user directories by handle.

## The map

`/GWSPH/groups/bendallgrp/admin/user_map.tsv`: tab-separated, one member per line.

```text
# linux_user	handle	full_name	added	email	role
u0000001	jane-doe	Jane Doe	2026-01-01	jane.doe@example.edu	user
```

- **Stored on the cluster only.** It is not in this repository, so names don't end up in a public GitHub Pages site. `templates/user_map.example.tsv` shows the format.
- `admin/` is group-only (2770), so only members can read it.
- Handles are lowercase letters, digits, `_` and `-`, and unique. Linux usernames are unique too. `role` is `user` or `admin` (default `user`); `email` may be empty. Like names, emails stay on the cluster only.

Admin-only scripts (`init-group-dir.sh`, `link-local.sh`, `user-map-add.sh`, `install-modulefiles.sh`) check that `whoami` has `role` = `admin` here. The first admin is added by hand ([setup-admin prerequisites](setup-admin.md#bootstrap-the-user-map-with-yourself-as-admin)).

```bash
# admin only, from the checkout (not linked into local/bin):
scripts/user-map-add.sh u0000001 jane-doe "Jane Doe" jane.doe@example.edu   # role defaults to user
scripts/user-map-add.sh u0000002 bob-roe "Bob Roe" bob.roe@example.edu admin

# anyone (shell functions from the group shell setup):
user-map-lookup jane-doe                 # -> u0000001
user-map-lookup u0000001                 # -> jane-doe
user-map-list
```

## Directory convention

```text
users/jane-doe/        real directory
users/.u0000001  ->  jane-doe            dot-link named after the Linux username
```

The same pair exists under `/scratch/bendallgrp/users/`. Scripts and templates use the dot-link (`users/.$USER`), so they work without a map lookup. `scripts/init-user.sh` creates both the directory and the link on NFS and scratch. It refuses to run for a user who isn't in the map yet.

## Readable `ls` and `squeue`

`scripts/hpc-aliases.sh` provides output filters. They are loaded for you by the [group shell setup](11-shell-setup.md); to use them on their own, source the file from `~/.bashrc`:

```bash
source /GWSPH/groups/bendallgrp/local/etc/hpc-aliases.sh
```

| Function | Use |
|---|---|
| `lsh [args]` | `ls -l` with owner/group names mapped |
| `sqh [args]` | `squeue` with usernames mapped |
| `hpc_filter` | stdin filter; works with any command, e.g. `sacct ... \| hpc_filter` |
| `hpc_whoami` | your handle |
| `user-map-lookup NAME` | the handle for a Linux username, or the username for a handle |
| `user-map-list` | the whole map as a table |

### Optional: make plain `ls` show handles

Set `HPC_WRAP_LS=1` in your `~/.bashrc` **before** the group shell setup block:

```bash
export HPC_WRAP_LS=1
```

On a terminal, long listings (`ls -l`, `-la`, `-al`, `-g`, `-o`, `--format=long`) then show handles; every other `ls`, and every `ls` in a pipe or script, is the normal `ls` and keeps its columns and colors. The wrapper keeps `ls`'s exit status and replaces any `alias ls=...` you had. Run `command ls` to bypass it. Leave `HPC_WRAP_LS` unset and `lsh` remains the explicit alternative.

Only whole tokens that equal a Linux username are replaced, so dot-links and handles in paths are untouched. A longer handle shifts columns slightly. The wrappers only change what you see; files keep their real owners.

## Adding a member

The step-by-step checklist is in [First-time admin setup](setup-admin.md#add-a-new-member) (admin side) and [First-time user setup](setup-user.md) (member side).
