# First-time admin setup

One-time setup of the group's directories, tooling and shell environment, followed by the routine admin tasks. Members do their own part in [First-time user setup](setup-user.md).

Run commands on a Pegasus login node. Every setup script supports `--dry-run`; use it first.

## 0. Prerequisites

RTS must already have created both roots with the Unix group and the setgid bit:

```bash
ls -ld /GWSPH/groups/bendallgrp /scratch/bendallgrp
# expect: drwxrws--- ... MG-bendallgrp ...   (the "s" in the group triplet is setgid)
id                                    # MG-bendallgrp should be in your groups
```

Members cannot `chgrp`, so the scripts rely on the setgid bit and never change group ownership ([Permissions](03-permissions.md)).

### Bootstrap the user map with yourself as admin

`init-group-dir.sh`, `link-local.sh`, `user-map-add.sh` and `install-modulefiles.sh` are admin-only: each checks that your Linux username (`whoami`) is listed with role `admin` in `admin/user_map.tsv`, and exits otherwise. Nothing exists yet, so create `admin/` and write the first line by hand (once). `init-group-dir.sh` later adopts the directory (it is idempotent); after that, use `user-map-add.sh` for everyone else, including further admins.

```bash
mkdir -p /GWSPH/groups/bendallgrp/admin
chmod 2770 /GWSPH/groups/bendallgrp/admin  # group-only; inherits the group from the setgid root
cd /GWSPH/groups/bendallgrp/admin
printf '# linux_user\thandle\tfull_name\tadded\temail\trole\n' > user_map.tsv
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(whoami)" <your-handle> "<Your Name>" "$(date +%F)" <you@gwu.edu> admin >> user_map.tsv
chmod 644 user_map.tsv                     # only you write
cat user_map.tsv
```

Fields are separated by tabs, as the `printf` formats produce; see [Usernames and handles](10-user-names.md). The map is the only authority for admin rights, so keep it writable only by admins.

## 1. Create the directory layout

Clone the repo temporarily to get the setup scripts, then create the layout:

```bash
git clone git@github.com:bendall-lab/GWHPC-bendallgrp.git ~/GWHPC-bendallgrp
cd ~/GWHPC-bendallgrp
scripts/init-group-dir.sh --dry-run        # review
scripts/init-group-dir.sh
```

The script stops with an error if either root is missing, and warns if a root has the wrong group or no setgid bit. Fix that with RTS rather than working around it. The layout it builds is described in [Directory layout](02-directory-layout.md). Re-running is safe; directories you don't own keep their mode.

## 2. Make the permanent checkout

```bash
cd /GWSPH/groups/bendallgrp/software/tools
git clone git@github.com:bendall-lab/GWHPC-bendallgrp.git GWHPC-bendallgrp.git
rm -rf ~/GWHPC-bendallgrp                  # the temporary clone
```

You own this checkout and are the only one who runs `git pull` in it. Members never write there.

## 3. Publish the user-facing scripts

```bash
cd /GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git
scripts/link-local.sh --dry-run
scripts/link-local.sh
ls -l /GWSPH/groups/bendallgrp/local/bin /GWSPH/groups/bendallgrp/local/etc
```

This symlinks the scripts members run into `local/bin/` and the files they source into `local/etc/`. After this, a `git pull` in the checkout is all it takes to update what everyone runs. Re-run `link-local.sh` only after adding or renaming a user-facing script (and add new ones to the arrays inside it). Why `local/` is separate from `software/` is explained in [Directory layout](02-directory-layout.md#local-vs-software).

## 4. Create the user map and add members

The map from Linux usernames to handles lives only on the cluster, in `admin/user_map.tsv` ([Usernames and handles](10-user-names.md)). You are already in it from the prerequisites. Add each member (use `admin` as the last argument only for further admins):

```bash
cd /GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git
scripts/user-map-add.sh <linux_user> <handle> "<Full Name>" [<email> [user|admin]]
cat /GWSPH/groups/bendallgrp/admin/user_map.tsv     # or `user-map-list` once step 5 is done
```

`user-map-add.sh` is admin-only and is not linked into `local/bin`. Members only read the map, through the `user-map-lookup` and `user-map-list` shell functions. The map file is writable only by you.

## 5. Set up your own account

```bash
S=/GWSPH/groups/bendallgrp/local/bin
$S/install-shell-setup.sh --dry-run
$S/install-shell-setup.sh
source ~/.bashrc
init-user.sh                               # your users/<handle>, plus the .<linux_user> link
```

Details of what the shell setup does are in [Group shell setup](11-shell-setup.md).

## 6. Check it works

```bash
echo $BENDALLGRP_HOME && ls -ld "$BENDALLGRP_HOME"/
lsh /GWSPH/groups/bendallgrp/users               # owners shown as handles
new-project.sh --dry-run test_project

# On a compute node: confirms /local and shows which filesystems are visible
srun --partition=cpu --cpus-per-task=1 --mem=1G --time=0-00:05:00 check-node-storage.sh
```

`/local` is the node-local disk. If it is also writable on compute nodes, enable `tmpdir` in `templates/project/profiles/slurm/config.yaml`.

## 7. Reference data (optional, when ready)

Clone the `referenceDB` workflow into `software/workflows/`, point its `db_dir` at `shared_resources/references/refDB` and its `build_dir` at scratch, then build. Workflows stage references to the scratch mirror automatically; see [Reference data](09-references.md).

## 8. Confirm with RTS and record the answers

These are marked **VERIFY** in the docs. Replace each marker with the real answer.

| Question | Where it is recorded |
|---|---|
| Snapshot and backup policy for the group directory (believed to be none) | [Storage tiers](01-storage-tiers.md) |
| Whether ACLs can be set from Pegasus | [Permissions](03-permissions.md) |
| Whether a crontab entry actually fires on a login node (`crontab` is installed) | [Reference data](09-references.md) |
| Which Slurm account new members get. Accounting enforces associations; two members (including the admin) are in `cbi` and the rest in `bendallgrp`, so new members are presumed `bendallgrp`. Check with `sacctmgr show assoc user=<user> format=user,account` after RTS adds them | [SLURM and partitions](05-slurm-and-partitions.md) |

## Routine admin tasks

### Add a new member

1. RTS adds them to the Unix group `MG-bendallgrp` (request through the IT Help portal or hpchelp@gwu.edu).
2. Add them to the map, from the checkout: `scripts/user-map-add.sh <linux_user> <handle> "<Full Name>" <email> [user|admin]`.
3. Tell them to follow [First-time user setup](setup-user.md). They run `init-user.sh` themselves so their directories are owned by them.

### Publish or update a modulefile

Modulefiles live in the repo under `modulefiles/` and are copied (not linked) to `software/modulefiles/`, so members only see a change when you publish it:

```bash
cd /GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git
git pull
scripts/install-modulefiles.sh --dry-run
scripts/install-modulefiles.sh
```

See [Installed apps](apps/index.md) and, for an example, [Miniforge3](apps/miniforge3.md).

### Update the scripts or docs

```bash
cd /GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git
git pull
scripts/link-local.sh        # only if a user-facing script was added or renamed
```

A `git pull` takes effect for everyone immediately, including `group-bashrc.sh` at their next login, so review changes to shell files before pulling. Pushing to `main` publishes the docs site ([Publishing these docs](08-publishing-docs.md)).

### Remove a member

Remove them from the Unix group through RTS, and move their `users/<handle>` and scratch directories out of the way when they are no longer needed. Remove their line from `admin/user_map.tsv` only after any of their files that others rely on have been reassigned, since `lsh` will otherwise show the raw username.
