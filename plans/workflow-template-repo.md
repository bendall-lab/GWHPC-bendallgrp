# Plan: `bendall-lab/snakemake-workflow-template-hpc` (Pegasus-ready Snakemake template repo)

Handoff plan for an agent starting in a new, empty repo. Everything it needs from the
`GWHPC-bendallgrp` repo is quoted or pointed to here. Status: **plan only, nothing created yet**
(the planning session could not fork; its GitHub access was limited to `GWHPC-bendallgrp`).

## 0. Scope decision (supersedes anything below that conflicts)

The template is a **bare Snakemake repo with no domain rules**: upstream layout and CI, plus the HPC
configuration in section 4. No example rules beyond one trivial smoke-test rule needed for CI/dry-run
(delete it if CI can pass without it). No cookiecutter/Copier; GitHub "Use this template" only, with a
small placeholder-replacing `scripts/init-project.sh`.

Domain workflows (for example single-cell gene expression) are separate repos made from this template.
Their design is sketched in section 11; it is not part of the template's first milestone.

## 1. Goal

A GitHub **template repository** in the `bendall-lab` org that gives a new Snakemake 9+ workflow:

1. the community-standard layout and CI from
   [snakemake-workflows/snakemake-workflow-template](https://github.com/snakemake-workflows/snakemake-workflow-template)
   (its examples removed);
2. out-of-the-box behaviour on GW's Pegasus cluster: SLURM profile, `.snakemake/` and
   intermediates on scratch, results location handled, conda envs in a shared prefix,
   reference staging, and the group's unix-permission conventions.

It must stand on its own: no dependency on the `GWHPC-bendallgrp` checkout at run time (see 6).

## 2. Setup steps (repo creation)

1. Create `bendall-lab/<name>` from the upstream template, either "Use this template" (clean history,
   preferred) or a fork. Suggested name: `snakemake-workflow-template-hpc`. Replace the upstream
   placeholders `<owner>`, `<repo>`, `<name>`, `<description>`.
2. Settings, Template repository: enable. Keep it **private** until reviewed (no real names or
   internal paths that should not be public; see 7).
3. Keep upstream's MIT `LICENSE` unless the lab decides otherwise; keep an attribution line in README.
4. Record the upstream commit used, for future diffs against upstream: `docs/UPSTREAM.md`.

## 3. Upstream layout and what to do with each piece

Upstream (observed): `.github/workflows/`, `.test/config/`, `config/` (`config.yaml`, `README.md`),
`profiles/` (workflow-specific profiles), `workflow/` (rules, Snakefile), `.gitignore`,
`.snakemake-workflow-catalog.yml`, `CHANGELOG.md`, `LICENSE`, `README.md`.
**VERIFY** by reading the repo at start; the above came from a summary, not a full listing.

| Upstream | Action |
|---|---|
| `workflow/Snakefile`, `workflow/rules/*` | Keep the structure; delete example rules. Leave at most one trivial `# REPLACE ME` smoke-test rule so CI and dry-runs work (see section 0). |
| `config/config.yaml`, `config/README.md` | Keep; add HPC keys (4). Rewrite README to document them. |
| `.test/` | Keep; shrink to the tiny example. Add `.test/config/hpc-local.yaml` that points scratch paths at a temp dir so CI runs without Pegasus. |
| `.github/workflows/` | Keep lint + dry-run + small test run (`--sdm conda`). Add shellcheck for `run.sh`/scripts and a placeholder-leftovers check. |
| `profiles/` | Replace with `profiles/pegasus/config.yaml` (4.3) and `profiles/local/config.yaml` (CI/laptop). |
| `.snakemake-workflow-catalog.yml` | Delete or leave disabled: the repo is private/internal; catalog registration is for public workflows. Remove again from generated projects. |
| `CHANGELOG.md` | Reset to an empty Keep-a-Changelog stub. |
| `README.md` | Rewrite: what this template is, "Use this template" steps, HPC usage, per-project TODO checklist. Delete upstream badges that do not apply. |

## 4. HPC implementation to add

All of this is already implemented and exercised in `GWHPC-bendallgrp/templates/project/`
(files named below). Port it; do not redesign it without a reason.

### 4.1 Storage design rule

Code on NFS (Qumulo, `/GWSPH/groups/bendallgrp`), heavy work on scratch (Lenovo DSS,
`/scratch/bendallgrp`). Snakemake runs with `--directory` on scratch so `.snakemake/` (locks,
metadata, conda/script caches) and all relative-path intermediates live on scratch.
**Do not use `--shadow-prefix` for this**: it only relocates `shadow:` rule execution, not `.snakemake/`.
(If the request to "shadow .snakemake" meant this, `--directory` is the answer.)
Scratch is purged (threshold believed 60 or 90 days, probably atime-based; **VERIFY** with RTS), so
anything that must persist must be copied to NFS.

### 4.2 `run.sh` (launcher)

Port `templates/project/run.sh`: `mkdir -p $WORKDIR; exec snakemake --snakefile ... --directory $WORKDIR --workflow-profile profiles/pegasus "$@"`.
Changes for standalone use:

- Replace the copy-time `@PLACEHOLDER@` substitution with runtime resolution: `PROJECT_DIR` from the
  script's own location (resolve symlinks), `WORKDIR=${SCRATCH_ROOT:-/scratch/bendallgrp}/users/.${USER}/${PROJECT_NAME}`.
  `PROJECT_NAME` defaults to the repo directory name. Allow env overrides `GROUP_ROOT`, `SCRATCH_ROOT`.
- Note `users/.${USER}` is the dot-link to the member's handle directory (usernames are
  meaningless; dirs are named by handle). If the dot-link is missing, fail with a message pointing to `init-user.sh`.
- Keep `--workflow-profile` (Snakemake 9+). Support `./run.sh -n` dry run.
- Docs line: Snakemake must stay alive while jobs queue; run in `tmux`/`screen` or an `sbatch` wrapper. Consider shipping `submit.sbatch` (partition `cpu`, 1 core, long runtime) as the wrapper.

### 4.3 SLURM profile (`profiles/pegasus/config.yaml`)

Port `templates/project/profiles/slurm/config.yaml`:

- `executor: slurm` (needs `snakemake-executor-plugin-slurm`), `jobs: 100`, `latency-wait: 60`
  (NFS/DSS visibility lag), `printshellcmds`, `rerun-incomplete`, `use-conda: true`,
  `conda-prefix: /GWSPH/groups/bendallgrp/software/conda/snakemake_envs`.
- `default-resources`: `slurm_partition: cpu`, `runtime: 240` (minutes), `mem_mb: 4000` (Pegasus
  default is 4 GB per core; always state explicitly), `cpus_per_task: 1`.
- Partitions (live `sinfo` beats the Rev B guide): `debug`, `longJob`, `basestar` **no longer exist**;
  `cpu` is default; `nano` (30 min) is the quick-test partition. Document a `--profile` override or
  a `--slurm-partition nano` hint for smoke tests.
- **No `slurm_account`**: not typed; Slurm enforces each user's default association (admin's is
  `cbi`). New members need an association via RTS, otherwise submission fails. Document this in README troubleshooting.
- GPU rules: `slurm_partition: gpu` + `slurm_extra: "'--gres=gpu:<TYPE>:1'"`; find `<TYPE>` with
  `sinfo -o "%P %G"`. Keep as a commented example under `set-resources`.
- Node-local scratch is believed to be `/local` and is **unverified**; keep `tmpdir: /local`
  commented out with a pointer to `check-node-storage.sh`. Tell rules to pass `-T {resources.tmpdir}`
  to sort-type tools. Keep large temp off NFS and DSS.
- Resource naming reference: `GWHPC-bendallgrp/docs/05-slurm-and-partitions.md` and `docs/06-snakemake.md`.

### 4.4 Config (`config/config.yaml`)

Add an `hpc:` block, no baked-in user names:

```yaml
hpc:
  group_root: /GWSPH/groups/bendallgrp
  scratch_root: /scratch/bendallgrp
  results_dir: null        # null -> <workdir>/results (scratch); set to an NFS path to write finals there
  publish_dir: null        # optional NFS dir that `publish` copies final deliverables to
references:
  master: /GWSPH/groups/bendallgrp/shared_resources/references/refDB
  mirror: /scratch/bendallgrp/shared/references/refDB
```

Plus a JSON-schema `workflow/schemas/config.schema.yaml` validating it (upstream style, `snakemake.utils.validate`).
Sample sheet `config/samples.tsv` with a schema, as in `templates/project/docs/samples.tsv` (column `sample`).

### 4.5 Results location (**decision needed; flagged**)

The existing group design rule is: code and *final results on NFS*, intermediates on scratch.
The request here says results go to scratch. Recommended reconciliation, implemented with the `hpc.results_dir` / `hpc.publish_dir` keys above:

- Default: everything including `results/` is relative to the scratch workdir (fast, off NFS).
- A final `publish` rule (target `rule publish`, a `localrule`) rsyncs deliverables to `hpc.publish_dir` on NFS
  when set. Scratch is purged, so the README must say "unpublished results are disposable".
- If the lab prefers NFS-final as before, set `results_dir` to an NFS path; no code change.

Ask the user to confirm the default before release.

### 4.6 Reference staging (`workflow/rules/stage_reference.smk`)

Copy `templates/project/rules/stage_reference.smk` verbatim, adapting only the include path. Behaviour to preserve (rationale in `docs/09-references.md`):

- `ref_staged("GRCh38")` marker, `ref_path("GRCh38", "star_2.7.11b")` mirror path; `temp()` marker so
  staging re-runs next time; rsync every time because a purge can remove individual files.
- `rsync -rl --size-only --delete --omit-dir-times --chmod=Dug+rwx,Do+rx,Dg+s,Fug+rw,Fo+r`; no `-t`
  (mirror mtimes = copy time; unchanged files not read, so atime is not refreshed by the check).
- `flock` on `${mirror}.locks/<ref with / -> __>.lock`; the same lock path convention as `sync-references.sh`. Do not change one without the other.
- Runs as a SLURM job (not `localrule`), 1 thread, `mem_mb=1000`, `runtime=120`.
- Build indexes under new directory names (tool version in name); same-size in-place changes are invisible to `--size-only`.
- Master is built by the separate `referenceDB` workflow (`bendall-lab/referenceDB`).

### 4.7 Permissions

Members cannot `chgrp`. Unix group is `MG-bendallgrp` (not the directory name). Admin-created roots
are setgid, so new files inherit the group. Therefore: **no `chgrp` calls anywhere**; set modes only
(`g+rw`, dirs `g+s`) and, where a script creates directories, verify the root is setgid rather than fixing it.
Add `umask 002` in `run.sh` so shared outputs are group-writable.

### 4.8 Conda envs

Rule envs under `workflow/envs/*.yaml`, built once into the shared `conda-prefix` so members reuse
them (`docs/04-conda.md`). Miniforge is installed as a group app (`docs/apps/miniforge3.md`, module
`miniforge3`). Document `module load` vs. a snakemake env: `mamba create -n snakemake -c conda-forge -c bioconda snakemake snakemake-executor-plugin-slurm`.
Consider shipping `envs/snakemake.yaml` pinning Snakemake >= 9 and the plugin.

## 5. Bootstrapping a project from the template

Two supported paths; implement path A first.

- **A. GitHub "Use this template"**, then clone to `/GWSPH/groups/bendallgrp/projects/<NAME>` (NFS) and run `./run.sh -n`.
  Provide `scripts/init-project.sh` that replaces upstream placeholders (`<owner>/<repo>/<name>/<description>`) and
  deletes template-only files (this plan, `docs/UPSTREAM.md`, the catalog file). Support `-n`.
- **B. Later**: teach `GWHPC-bendallgrp/scripts/new-project.sh` to `git clone` this template instead of copying
  `templates/project/` (then delete that copy and update `docs/06`, `docs/07`). Not part of the first milestone.

Tell members where scratch lives: `/scratch/bendallgrp/users/.${USER}/<project>/` (also
`users/<handle>/...`). Each project is its own git repository.

## 6. Standalone vs. multi-repo

Recommendation: **two repos, with one-way knowledge flow**.
- This template repo holds only what a workflow needs at run time (profile, run.sh, staging rule, config schema).
  It reads absolute cluster paths from `config/config.yaml`; it never reads `GWHPC-bendallgrp`.
- `GWHPC-bendallgrp` stays the cluster-ops repo (directory/permission scripts, docs, modulefiles) and links
  to the template from `docs/07-new-project.md` and `docs/06-snakemake.md`.
- To work across both with one agent session, check both out side by side (for example
  `~/Development/GWHPC-bendallgrp` and `~/Development/<template>`), or add the template as a second repo to the
  Claude Code session. A git submodule is not recommended (it complicates "Use this template").
- The long-form HPC rationale lives in `GWHPC-bendallgrp/docs`; the template's README should only link to it
  (public-bound or not, link by URL, do not copy).

## 7. Things that must not leak

- No real names or the username-to-name map (`admin/user_map.tsv`); it must never be committed. Only generic
  `$USER` / handle patterns.
- Internal paths (`/GWSPH/groups/bendallgrp`, `/scratch/bendallgrp`) are acceptable only if the repo stays private
  or the lab agrees; otherwise move them to a single `config/hpc.yaml` documented as "edit for your group".
- Mark every unconfirmed claim **VERIFY** (project convention): node-local `/local`, scratch purge policy,
  cron availability on login nodes.

## 8. Verification checklist (before marking the template ready)

1. `snakemake --lint` and `snakemake -n` pass with the example rules (local profile, CI).
2. On Pegasus: `./run.sh -n`, then a real run on partition `nano` writes `.snakemake/` under
   `/scratch/bendallgrp/users/.$USER/<project>/` and **not** in the NFS checkout (`ls -a` the checkout).
3. Staging: run twice; second run is a fast no-op; delete a mirror file, re-run, confirm it is restored.
4. A file created by a job has group `MG-bendallgrp` and is group-readable (setgid inheritance works).
5. `shellcheck run.sh scripts/*.sh`. No leftover `TODO`/`<owner>`/`@...@` strings (CI check).
6. "Use this template" produces a repo that passes 1 and 5 unchanged.

## 9. Suggested order of work

1. Create repo from upstream template; strip examples; get CI green (local profile).
2. Add `profiles/pegasus`, `run.sh`, config + schema, `stage_reference.smk`.
3. `init-project.sh`, README, `config/README.md`.
4. Pegasus verification run (needs the user; the agent cannot reach the cluster).
5. Mark as template repo; update `GWHPC-bendallgrp` docs to link it (and optionally path B in 5).

## 10. Open questions for the user

1. Results default: scratch with optional publish (recommended) or NFS-final (existing rule)? See 4.5.
2. Repo name and visibility (private first?).
3. Keep upstream's CI/catalog files, or minimal?
4. Is `/local` node-local scratch confirmed yet (run `check-node-storage.sh` on a compute node)?

## 11. Later: domain workflows built on this template (design sketch)

Example: a single-cell expression workflow where data arrives from SRA, local files, or cloud storage.
Sources differ in the first few rules; downstream steps and results layout should not.

- **Normalization boundary.** Source-specific "ingest" rules (`ingest_sra.smk`, `ingest_local.smk`,
  `ingest_cloud.smk`) all produce the same canonical outputs (for example `01_raw/{sample}_R{1,2}.fastq.gz`
  plus a normalized `samples.tsv`). Everything downstream reads only canonical paths. This keeps the results
  directory identical regardless of source.
- **Select by sample sheet, not globally.** Give `samples.tsv` a `source` column (`sra|local|cloud`) and a
  `location` column. An input function (`get_raw(wildcards)`) picks the ingest rule per sample, so mixed-source
  projects work. A global `source:` config key is the simpler fallback.
- **Conditional includes.** `if "sra" in SOURCES: include: "rules/ingest_sra.smk"`, with `SOURCES` derived
  from the sheet. For reuse across workflows, Snakemake's `module` directive is available. **VERIFY** it fits
  before adopting.
- **Results layout from one place.** A single helper (for example `results("counts", sample)`) builds
  paths from a layout template in config, so layout changes (and any unavoidable per-source differences)
  are config, not rule edits. Keep source provenance in `results/provenance/<source>/`.
- **Interactive parameter choice.** A `scripts/configure` wizard (bash `select`, or Python with `questionary`)
  asks about source, species and reference, chemistry, and so on, then writes `config/config.yaml` and a
  samples template. It is a project-level tool, so the bare template needs nothing. Validate its output with
  the config JSON schema so hand-edited and wizard-made configs are equally checked.
- **HPC specifics per source:** SRA downloads need internet from a compute node (**VERIFY** that Pegasus
  compute nodes have outbound network; otherwise run ingest as a `localrule` on a login node or via a data-transfer
  node) and `prefetch`/`fasterq-dump` temp space on scratch, not NFS. Cloud pulls need credentials kept
  out of the repo.
