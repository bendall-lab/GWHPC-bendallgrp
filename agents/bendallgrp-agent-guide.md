# Bendall group cluster guide for AI agents

You are an AI coding or analysis agent working for a member of the Bendall group on GW's Pegasus HPC cluster. Read this file fully before running commands or writing files. It describes the group's directories, shared tools and rules. Where it conflicts with a general habit of yours, follow this file. Where it conflicts with an explicit instruction from your user, say so and ask.

This file is deployed at `/GWSPH/groups/bendallgrp/local/etc/bendallgrp-agent-guide.md`. Longer documentation is in the group's HPC guide (published from the `GWHPC-bendallgrp` repository; the checkout is `/GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git/docs/`). You work for one member, with that member's permissions. Anything you do is done as them.

Statements marked **VERIFY** are unconfirmed. Check live state (`sinfo`, `ls`, `module avail`) before relying on them, and do not repeat them to the user as fact.

## 1. First, orient yourself

Your shell may not have run the member's `~/.bashrc`. Check, and fix for the current session if needed:

```bash
whoami; umask; echo "$BENDALLGRP_HOME"      # expect umask 0002 and a path under users/
source /GWSPH/groups/bendallgrp/local/etc/group-bashrc.sh   # sets umask 002, env vars, PATH, modulepath
source /GWSPH/groups/bendallgrp/local/etc/hpc-aliases.sh    # user-map-lookup, lsh, sqh (optional)
type module                                 # Lmod; if missing, ask the user rather than guessing
```

Hostname tells you where you are: login nodes are for editing, light commands and job submission; compute nodes are where work runs (section 5).

## 2. Directory layout

| Path | What | Rules |
|---|---|---|
| `/GWSPH/groups/bendallgrp` (`$BENDALLGRP_ROOT`) | Group directory on NFS (Qumulo). Persistent. | Code, configs, final results. No heavy parallel I/O, no millions of small files. |
| `/scratch/bendallgrp` (`$BENDALLGRP_SCRATCH`) | Scratch (Lenovo DSS). Fast, **purged**, not backed up. | Raw inputs staged for analysis, intermediates, Snakemake working directories. |
| `/local` (`$TMPDIR` inside jobs) | Node-local SSD. Wiped when the job ends. | Temporary files for one job. |

```text
/GWSPH/groups/bendallgrp/
├── admin/            group-only; holds user_map.tsv. Do not read beyond what section 3 allows. Never write.
├── shared_resources/
│   ├── references/refDB/   master reference genomes/indexes. READ-ONLY for you.
│   └── databases/          shared databases. Read-only.
├── software/         installed software; admin-managed. Do not write (see section 6).
│   ├── modulefiles/        Lmod modulefiles (published by the admin)
│   ├── conda/envs/         shared conda environments, read-only
│   └── tools/GWHPC-bendallgrp.git/   the group's scripts and docs; admin-owned. Never write.
├── local/            group glue. bin/ (on PATH) and etc/ (sourced files, this guide). Read-only.
├── projects/<project>/   one git repository per project, from new-project.sh (section 7)
├── users/<handle>/       a member's small personal files; users/.<linux_user> is a symlink to it
└── archive/          finished projects. Read-only.

/scratch/bendallgrp/
├── users/<handle>/<project>/   Snakemake working dir: .snakemake/, 01_raw/, 02_intermediates/
│                               (also reachable as users/.<linux_user>/...)
└── shared/references/refDB/    purge-tolerant mirror of the reference master
```

Where new things go:

- Code, configs, final tables and figures: `projects/<project>/` on NFS.
- Raw inputs, intermediates, `.snakemake/`, anything big or written by many jobs: `/scratch/bendallgrp/users/.$USER/<project>/`.
- Per-job temporary files (sort buffers, extraction): `$TMPDIR` on `/local`.
- Scratch is **not a backup**. Never leave the only copy of a result, script or notebook there.

## 3. User names and handles

Linux usernames (`u1234567`-style) are meaningless. The group names people and directories by **handle**.

- Address a user's directories through the dot-link: `$BENDALLGRP_HOME` and `$BENDALLGRP_SCRATCH_HOME`, or `users/.$USER`. Do not guess handles from usernames or full names.
- To translate one name, use `user-map-lookup <username-or-handle>`. To make `ls`/`squeue` output readable, use `lsh`, `sqh`, or pipe any output through `hpc_filter`.
- `admin/user_map.tsv` contains real names and email addresses. This repository and its docs are public-bound, so **never copy names, emails or the map's contents into project files, commits, issues, logs, job scripts or anything sent off the cluster.** Use handles. Do not dump `user-map-list` unless the user asks for it for this session. Never write to the map; it is admin-only.
- When you report who owns something, use handles.

## 4. Permissions: files must be usable by the group

- The roots are setgid, so new files inherit group `MG-bendallgrp`. Keep `umask 002` for every write session (check it, as in section 1). The user's files then stay group-readable and group-writable.
- Do **not** call `chgrp` (members cannot; it is unnecessary because of setgid). Do not use ACLs: they are not supported here. Do not `chmod 777` or `chmod -R` broadly. If files from an archive or download arrive without group write, repair only that project: `chmod -R g+rwX <that-project-dir>`.
- Make finished raw data read-only (`chmod -R a-w`), never modified. Never edit raw data in place; derive copies instead.
- Do not weaken the permissions of `admin/`, `software/` or `local/`, and do not try to work around a permission error on them. If you hit one, stop and tell the user: it is probably intended.

## 5. Compute: login nodes, Slurm, local disk

**Login nodes (shared by everyone):** edit files, run `git`, `ls`, `less`, dry runs (`snakemake -n`), submit jobs, and keep a workflow manager alive in `tmux`. Do not run alignment, sorting, compression of large files, large `find`/`du` sweeps of NFS or scratch, package builds with many files, or anything that uses more than one core or a few GB of memory for more than a minute. Run it in a job instead.

**Interactive or one-off work:**

```bash
srun --partition=nano --cpus-per-task=2 --mem=4G --time=0-00:10:00 --pty bash   # quick test (30 min limit)
srun --partition=cpu  --cpus-per-task=4 --mem=16G --time=0-02:00:00 --pty bash
```

**Rules for every Slurm submission:**

- Always state `--time`, `--mem` (or `--mem-per-gpu`) and `--cpus-per-task`. Memory is enforced by cgroups; the default is only 4 GB per core. Request what the job needs, not the maximum.
- `cpu` is the default partition (14-day limit). `nano` (30 min) is the quick-test partition. GPUs need `--partition=gpu --gres=gpu:<TYPE>:N` (types, e.g. `v100`, `a100`; find them with `sinfo -o "%P %G %l"`). `debug`, `longJob` and `basestar` no longer exist. Partitions change: run `sinfo -s` rather than trusting this file.
- Do **not** pass `--account`; the user's default association applies. If a job is rejected for an association error, tell the user to contact the group admin (RTS adds associations).
- Do not use `--exclusive`, request GPUs "just in case", or submit a large array or hundreds of jobs without showing the user the plan and getting a go-ahead. Test with one sample on `nano` first.
- Only cancel jobs the user asked you to cancel, and only their own (`squeue -u "$USER"`, or the `qstat` shortcut). Never `scancel -u`/`scancel` by partition or name patterns without confirming the exact job list.
- Debug failed jobs from facts: `sacct -X -j <id> -o ReqTRES%50,AllocTRES%50,State,ExitCode,Elapsed` and the job's `.out`/`.err` files.

**Use node-local disk when it fits the job.** Inside a job, put temporary files on `$TMPDIR` (which is `/local`) instead of NFS or scratch: `T=$(mktemp -d -p "$TMPDIR"); trap 'rm -rf "$T"' EXIT`. Jobs share `/local`, so always create a private `mktemp -d` directory and delete it, and never write under a fixed name. Copy inputs in and results out; node-local data is gone when the job ends. Check `df -h "$TMPDIR"` first if you need a lot of space (the disk is 800 GB, shared with the boot partition). If `/local` is not writable on the node, fall back to scratch, not NFS.

**Storage etiquette:**

- Never write intermediates, `.snakemake/` or many small files to the group directory. Run workflows with the working directory on scratch (section 7).
- Do not run `touch`, scripted file reads or similar to keep scratch files from being purged. Scratch is purged ad hoc (reported as at the start of the month, 30-day window on mtime and atime). If something must survive, copy it to NFS.
- Avoid creating environments full of small files on NFS. Prefer the shared modules and a project's locked pixi environment over ad hoc installs.

## 6. Software: use modules, do not install into the group tree

```bash
module avail                 # group modules appear once group-bashrc.sh has set MODULEPATH
module load pixi             # package manager; projects use it (pixi.toml / pixi.lock)
module load snakemake        # Snakemake 9+ with the Slurm plugin (one version at a time)
module load miniforge3       # conda + mamba, conda-forge/bioconda (one conda module at a time)
module help <name>           # short usage and a pointer to the docs
```

- Load only what the job needs, with explicit versions in job scripts (`module load snakemake/9.27.0`), and `module list` in logs for reproducibility. Check `module avail` for what exists now.
- Never write to `software/`, never edit or add modulefiles, and do not run installers there. Group software and modulefiles are installed by the admin from the group repository. If a tool is missing, tell the user to ask the admin.
- Personal tools go in the user's own space: conda environments in `~/.conda/envs` (the module's default), or pixi/conda environments inside a project. Do not install to the shared `software/conda/envs` unless the user states they are a designated maintainer.
- Do not run `conda init`, edit `~/.bashrc` or `~/.bash_profile`, or load several conda or Python modules at once. `scripts/install-shell-setup.sh` (on PATH as `install-shell-setup.sh`) is the supported way to set up a member's shell, and the user runs it.
- Rules in Snakemake workflows use `conda:` environments, built once for the group under `software/conda/snakemake_envs/` by the project profile. Let the profile handle it.

## 7. Projects and workflows

- **New project:** `new-project.sh <name>` (on PATH; `--dry-run` first). It copies the Snakemake 9+ template to `projects/<name>/` and creates the scratch working directory. Do not hand-copy template files.
- **Run:** inside the project, `module load pixi` then `./run.sh -n` (dry run) then `./run.sh`. `run.sh` runs Snakemake with code and profile on NFS and `--directory` on scratch (`/scratch/bendallgrp/users/.$USER/<project>`), so `.snakemake/` and intermediates stay on scratch. Do not bypass it by running Snakemake with a working directory on NFS. `--shadow-prefix` does not do this.
- Snakemake must stay alive while jobs run: start `./run.sh` in `tmux` (installed on the login nodes) or in a small `sbatch` wrapper. `cluster.yaml` and `--cluster` do not work in Snakemake 8+; resources are set in `profiles/slurm/config.yaml` (`slurm_partition`, `runtime` in minutes, `mem_mb`, `cpus_per_task`).
- Each project is its own git repository. Commit code, configs, sample sheets, `pixi.toml` and `pixi.lock`. Do **not** commit raw data, large outputs, or anything under `01_raw/`, `02_intermediates/` or `.snakemake/`; keep names, emails and credentials out of commits. Do not push to a remote, open pull requests, or publish anything without the user's go-ahead. Never force-push.
- Final tables and figures go to `results/` in the project; intermediates stay on scratch.
- When the user says a project is finished: do not move or delete anything into `archive/` or clean scratch on your own. Describe what you would do and let them confirm.

## 8. Reference data

Reference genomes, annotations and indexes live in `shared_resources/references/refDB` (NFS master) with a purge-tolerant mirror at `/scratch/bendallgrp/shared/references/refDB`.

- **Never write to the master.** It is built by the separate `referenceDB` workflow; ask the user before touching anything there.
- Workflows read the mirror, not the master, for large files. In a project, use the template's `rules/stage_reference.smk`: list `ref_staged("GRCh38")` as an input and take paths from `ref_path("GRCh38", "<subdir>")`.
- To refresh the mirror by hand: `sync-references.sh --dry-run`, then `sync-references.sh <REF>` (on a compute node or login node, not as a tight loop). It uses a lock; do not delete the lock directory.
- Build new indexes under a new directory name that includes the tool version, instead of overwriting one in place.

## 9. Boundaries: do not do these

1. Do not run admin-only scripts (`init-group-dir.sh`, `link-local.sh`, `user-map-add.sh`, `install-modulefiles.sh`). They check that the caller is a group admin and are not for agents.
2. Do not modify `admin/`, `software/`, `local/`, `shared_resources/` (except as the user explicitly directs in a project's own build), `archive/`, or another member's `users/<handle>/` or project. You may read other members' group-readable files only when the user's task needs it.
3. Do not delete or overwrite data you did not create in this session without showing the user exactly what will go (`ls`/`du` of the exact path) and getting confirmation. This includes `rm -rf`, `mv` over an existing file, `rsync --delete`, and `git reset --hard`/`git clean` in a project with uncommitted work. Prefer an exact path to wildcards.
4. Do not read or print credentials: `~/.ssh`, tokens, `.netrc`, cloud keys, or environment variables that look like secrets. Do not put them into files or commands.
5. Do not send cluster data, file contents, paths or the user map to outside services (web uploads, paste sites, external APIs, gists) without the user's explicit instruction for that specific item. Data in this group may be sensitive or subject to agreements; **VERIFY** with the user what a dataset allows.
6. Do not run heavy computation on a login node, and do not leave long-running processes (watch loops, `sleep` polling, runaway `find`) behind. Stop what you start.
7. Do not try to bypass cluster controls: purge avoidance, quotas, partition limits, scheduler priority, other users' reservations, or permission errors.
8. Do not run `sudo` or attempt privilege escalation; you do not have root and should not seek it.
9. Cron does not work on Pegasus. Do not set up cron or `at` jobs. Do not set up recurring Slurm jobs (`scrontab`) unless the user asks.
10. Do not change shell startup files, global tool configs (`~/.condarc`, `~/.gitconfig`) or other personal settings unless the user asks for that change.
11. Do not assume a fact in this file is current when it is cheap to check. Run `sinfo`, `module avail` and `ls`; if the file is wrong, tell the user so the admin can fix it.

## 10. Working style

- Say what you plan to run before submitting jobs, writing under `projects/` or scratch, or changing more than a few files; keep the summary short.
- Clean up after yourself: delete your temp directories, remove stray test jobs, and say what remains on scratch and where. Test outputs go in a clearly named subdirectory (for example `scratch/.../_agent_tmp/`), not mixed into results.
- Show dry runs (`-n`, `--dry-run`) first for anything that creates, moves or removes files in bulk.
- Report outcomes plainly, with job IDs, paths and exit states. If something failed or you skipped a step, say so.
- Use handles, not usernames or real names, in what you write or commit.

## 11. Help

- Cluster problems (accounts, associations, outages, hardware): hpchelp@gwu.edu. Include the job ID and submission script.
- Group setup problems (new software, modulefiles, the user map, this guide): the group admin.
- Tell the user when you hit a question that needs one of these instead of working around it.
