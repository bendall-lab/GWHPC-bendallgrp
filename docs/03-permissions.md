# 3. Permissions and access

## Group ownership

All group directories are owned by the Unix group `MG-bendallgrp` (note that it differs from the directory name `bendallgrp`; `id` lists your groups and `ls -ld /GWSPH/groups/bendallgrp` shows the group on the directory). Membership is managed by RTS; request additions through the IT Help portal or hpchelp@gwu.edu.

The two roots, `/GWSPH/groups/bendallgrp` and `/scratch/bendallgrp`, were created by an admin with group `MG-bendallgrp` and the setgid bit set. The scripts never call `chgrp` (members can't): everything created beneath those roots inherits the group, and `init-group-dir.sh` only checks that the roots have the right group and setgid bit.

## setgid and umask

The setup scripts set the setgid bit (mode `2xxx`) on every directory, so new files and subdirectories inherit group `MG-bendallgrp` instead of the creator's primary group.

Every member should add this to `~/.bashrc` so files they create are group-writable:

```bash
umask 002      # group read/write; use 007 to also hide files from other users
```

Files copied or extracted from archives can still arrive without group write. Repair with:

```bash
chmod -R g+rwX /GWSPH/groups/bendallgrp/projects/<project>
```

## Modes used by the scripts

| Directory | Mode | Meaning |
|---|---|---|
| `admin/` | 2770 | group only |
| `shared_resources/databases`, `software/conda/envs`, `archive/` | 2755 | everyone in the group reads; only the owner (a designated maintainer) writes |
| everything else | 2775 | group read/write |

## Read-only raw data

```bash
chmod -R a-w /path/to/raw_data
```

## ACLs

ACLs cannot be set from the Pegasus login nodes. `setfacl -m` fails with "Operation not supported" on the group directory, `getfacl` only echoes the ordinary mode bits, and the `nfs4_getfacl`/`nfs4_setfacl` tools are not installed. Use plain POSIX permissions and group membership (`MG-bendallgrp`), as the rest of this page describes. To give someone access, ask RTS to add them to the Unix group.
