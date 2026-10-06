# Source from ~/.bashrc or ~/.zshrc:
#   source /GWSPH/groups/bendallgrp/software/workflows/GWHPC-bendallgrp/scripts/hpc-aliases.sh
# Shows human-readable handles in place of Linux usernames. Output only; nothing is modified.
#
#   hpc_filter      stdin filter: replaces whole-word Linux usernames with handles
#   lsh [ls args]   ls -l with owner/group names mapped
#   sqh [args]      squeue with usernames mapped
#   hpc_whoami      your handle
#
# Only tokens that exactly equal a Linux username are replaced, so paths like
# users/.u12345 (the dot-link) and users/<handle> are left alone. Columns may
# shift when a handle is longer than the username.

HPC_USER_MAP="${HPC_USER_MAP:-/GWSPH/groups/bendallgrp/admin/user_map.tsv}"

hpc_filter() {
    [ -r "$HPC_USER_MAP" ] || { cat; return; }
    awk -v mapfile="$HPC_USER_MAP" '
        BEGIN {
            while ((getline l < mapfile) > 0) {
                if (l ~ /^#/ || l == "") continue
                split(l, a, "\t"); m[a[1]] = a[2]
            }
        }
        {
            out = ""; s = $0
            while (match(s, /[A-Za-z0-9_.\/-]+/)) {
                pre = substr(s, 1, RSTART - 1); tok = substr(s, RSTART, RLENGTH)
                s = substr(s, RSTART + RLENGTH)
                if (tok in m) tok = m[tok]
                out = out pre tok
            }
            print out s
        }'
}

lsh()  { ls -l "$@" | hpc_filter; }
sqh()  { squeue "$@" | hpc_filter; }
hpc_whoami() { echo "$USER" | hpc_filter; }
