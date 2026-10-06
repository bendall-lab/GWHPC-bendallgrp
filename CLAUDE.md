# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Documentation and tooling for the Bendall group's directory space on GW's Pegasus cluster. There is no build or test tooling. The docs are plain Markdown meant for GitHub Pages (generator not yet chosen; MkDocs Material is recommended in `docs/08-publishing-docs.md`).

## Layout

- `docs/`: numbered reference docs plus two unnumbered onboarding pages, `setup-admin.md` and `setup-user.md` (the checklists for first-time setup and for adding a member; keep step-by-step procedures there, not in reference pages). `docs/index.md` is the TOC. Keep the TOC in `docs/index.md`, `README.md` and the `nav:` in `mkdocs.yml` in sync when adding or renaming a doc.
- `scripts/`: bash scripts that create the group, scratch, user, and project directories. They share `scripts/lib.sh`, support `-n`/`--dry-run`, and read `GROUP_ROOT`, `SCRATCH_ROOT`, and `UNIX_GROUP` overrides. Test them by pointing the overrides at a temp directory.
- `templates/project/`: Snakemake 9+ project skeleton copied by `new-project.sh`. Placeholders `@PROJECT_NAME@`, `@PROJECT_DIR@`, `@GROUP_ROOT@`, `@SCRATCH_ROOT@` are substituted at copy time.
- `Pegasus Researcher Guide to Research Allocation Rev B.pdf.md`: RTS's SLURM/TRES guide; the source for `docs/05`.

## Key facts

- Group dir (NFS, Qumulo): `/GWSPH/groups/bendallgrp`. Scratch (Lenovo DSS): `/scratch/bendallgrp`. Node-local scratch is believed to be `/local` and is unverified.
- Unix group is `MG-bendallgrp` (not the directory name); it is the `UNIX_GROUP` default in `scripts/lib.sh`. Members cannot `chgrp`: the admin-created roots are setgid, so scripts rely on group inheritance and only verify the roots (`check_root`). Do not add `chgrp` calls.
- Deployment: no release step. The permanent checkout is `$GROUP_ROOT/software/tools/GWHPC-bendallgrp.git`; `scripts/link-local.sh` symlinks user-facing scripts into `$GROUP_ROOT/local/bin` (executables, on PATH) and `local/etc` (sourced files). `local/` is group-authored glue; `software/` is installed/built software. Scripts therefore must resolve their own symlink (the `SCRIPT_DIR` line) and `group-bashrc.sh` uses fixed paths, not self-location. A new user-facing script needs adding to the arrays in `link-local.sh`. Admin-only scripts (`init-group-dir.sh`, `link-local.sh`, `user-map-add.sh`) are deliberately not linked; member-facing map reads are the `user-map-lookup`/`user-map-list` functions in `hpc-aliases.sh`, so no member-facing script can write the map.
- No SLURM `--account` is needed.
- Usernames are meaningless; user directories are named by handle (`users/<handle>/`, with a `users/.<linux_user>` symlink). The username-to-name map lives on the cluster at `admin/user_map.tsv` and must never be committed (real names stay out of this public-bound repo; only `templates/user_map.example.tsv` is tracked). Scripts and templates address user dirs via the dot-link. See `docs/10-user-names.md`.
- Reference data: master on NFS (`shared_resources/references/refDB`, built by the separate referenceDB workflow repo at `~/Development/referenceDB.git`), purge-tolerant mirror on scratch. Scratch purge is likely atime-based and unconfirmed. See `docs/09-references.md` before changing `stage_reference.smk` or `sync-references.sh`; both use the same lock path convention.
- Design rule: code and final results on NFS; Snakemake runs with `--directory` on scratch so `.snakemake/` and intermediates stay off NFS. `--shadow-prefix` does not do this.
- Mark unconfirmed statements **VERIFY** in the docs instead of asserting them.

## Reference resources

Skimmed at setup, not analyzed in depth. Consult them when a task needs context:

- **Pegasus (current system):** https://it.gwu.edu/hpc-pegasus. Hardware (CPU, GPU, high-memory nodes), storage (Qumulo NFS, Lenovo scratch), SLURM scheduler, 4 login nodes, access request and support links.
- **GW HPC onboarding:** https://github.com/gwuniversity/hpc-onboarding. Current official guide covering SSH keys, first login and 2FA, command-line basics, file transfer, and SLURM job submission. Follow its style and terminology.
- **Legacy docs:** https://github.com/gwcbi/HPC. Older Colonial One-era tutorials (bash, SLURM, modules, interactive jobs, permissions, file transfer, bioinformatics tools). Colonial One is the predecessor system, so verify details against the Pegasus docs before reusing them.

When the legacy and current docs disagree, the Pegasus and onboarding docs take precedence.
