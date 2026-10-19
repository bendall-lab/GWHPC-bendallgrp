# 12. Using AI agents on the cluster

If you run an AI coding agent (Claude Code, Codex, Gemini CLI, Cursor's agent mode or similar) on Pegasus, point it at the group's **agent guide**. The guide tells the agent how the group directory is laid out, how usernames and handles work, which modules exist, and what it must not do (write into `software/`, run analyses on login nodes, put intermediates on NFS, leak names from the user map, and so on).

The guide is at:

```text
/GWSPH/groups/bendallgrp/local/etc/bendallgrp-agent-guide.md
```

It is read-only for members and updates whenever the admin pulls the repository. The source is `agents/bendallgrp-agent-guide.md`. It is deliberately **not** called `AGENTS.md` or `CLAUDE.md` and is not placed in a directory an agent searches automatically, so no agent loads it unless you tell it to.

## Why you have to point the agent at it

Agents only read what they are given. Most tools auto-load a file called `AGENTS.md`, `CLAUDE.md` or similar from the directory they start in (and its parents), or from your home directory. They do not discover `local/etc/` on their own. Three ways to give the guide to an agent, from most to least robust:

### 1. Once, in your personal agent instructions (recommended)

Add a short pointer to the file your agent loads for every session. It stays out of the group directory and applies wherever you start the agent:

| Agent | Personal instruction file |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex CLI | `~/.codex/AGENTS.md` |
| Others | check the tool's documentation for its global instructions file |

Put this in it:

```markdown
## Bendall group cluster (Pegasus)

When working in /GWSPH/groups/bendallgrp, /scratch/bendallgrp, or on Pegasus for the Bendall
group, first read /GWSPH/groups/bendallgrp/local/etc/bendallgrp-agent-guide.md and follow it.
Its boundaries override your defaults. Use handles, never real names, in anything you write.
```

Use a pointer, not a copy. A copy goes stale when the group changes a rule.

### 2. Once per project

`new-project.sh` projects are their own git repositories, so you can add a project-level file that tells any agent that starts there what to read. Write only what is specific to the project, and keep the group rules in the guide:

```markdown
# AGENTS.md  (or CLAUDE.md, for Claude Code)

Read /GWSPH/groups/bendallgrp/local/etc/bendallgrp-agent-guide.md before doing anything.

Project notes:
- Question: <one line>. Inputs: <where they are on scratch or how to stage them>.
- Run with `module load pixi && ./run.sh -n`, then `./run.sh`, in tmux.
- Do not touch `data/` or the reference master.
```

The guide is a file on NFS, so use the absolute path; a relative link will not resolve from a project.

### 3. In a single prompt

For a one-off session, or an agent with no instructions file, say it in the first message:

> Read /GWSPH/groups/bendallgrp/local/etc/bendallgrp-agent-guide.md in full and follow it for this whole session. Tell me which parts apply to the task before you run anything.

Asking for the applicable parts makes you confirm that the agent actually read the file instead of skimming it.

## Starting a session: a checklist

1. Log in to Pegasus and start the agent **inside a project directory** (or `cdme`), not at `/` or in your home directory with a task that sweeps the filesystem.
2. Make sure the group shell setup is installed ([Group shell setup](11-shell-setup.md)), so `umask 002`, `PATH`, `BENDALLGRP_*` variables and the module path exist. Agents often run non-interactive shells that do not read `~/.bashrc`; the guide tells them to source `group-bashrc.sh` themselves.
3. Give the task, the project name, and any data location. Say which actions need your approval; the agent should already plan before submitting jobs.
4. Run the agent in `tmux` if you expect it to take a while, and keep its permission mode strict: approve writes outside the project, any `rm`, `scancel`, `sbatch` of arrays, and anything touching `software/`, `admin/` or `shared_resources/`.

## Good prompts

Be specific about the tier and the compute:

- "Create project `2026_atac_pilot` with `new-project.sh`, then write the first rule to align `01_raw/*.fq.gz` to GRCh38 using the staged reference. Dry-run it on one sample; do not submit anything yet."
- "Job 4123456 failed. Find out why with `sacct` and the `.err` file and propose a fix. Don't resubmit."
- "Sort this BAM with `samtools sort` in a job on the `cpu` partition, 8 cores, 32 GB, 2 hours, with temp files in `$TMPDIR`. Show me the script first."

Weak prompts invite expensive guesses: "run everything", "clean up scratch", "install whatever is missing".

## What the guide does and does not do

- It makes an agent **well-informed and cautious**, but it is text, not enforcement. Nothing stops an agent from ignoring it, or from running a command you approve. The Unix permissions, setgid directories and the admin-only checks in the scripts are the real controls ([Permissions](03-permissions.md)).
- Everything an agent does runs as you, with your permissions, your Slurm association and your scratch usage. You are responsible for what it submits.
- Do not paste data, the user map, tokens or keys into an agent's chat. Cluster data can be sensitive, and the agent's provider receives what the agent reads. Check your agent's data settings and your data agreements before pointing it at human-subjects data (**VERIFY** with the group lead).
- If the agent proposes something the guide forbids (writing to `software/`, installing into the shared environments, running admin scripts), say no and ask the admin instead.

## Reporting problems

If the guide is wrong, out of date, or an agent misread it, tell the group admin with the quote. The admin edits `agents/bendallgrp-agent-guide.md` in the repository, and the change reaches everyone with the next `git pull` ([admin tasks](setup-admin.md#publish-the-agent-guide)).
