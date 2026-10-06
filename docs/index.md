# Bendall Group HPC Guide

How the Bendall group organizes data, software, and workflows on GW's Pegasus cluster.

**Getting started:** [First-time admin setup](setup-admin.md) (group admin, once) and [First-time user setup](setup-user.md) (each new member).

**Reference:**

1. [Storage tiers](01-storage-tiers.md): what lives where and why
2. [Directory layout](02-directory-layout.md): group, scratch, and per-project structure
3. [Permissions and access](03-permissions.md): groups, setgid, umask, read-only data
4. [Conda and software](04-conda.md): shared environments and package caches
5. [SLURM and partitions](05-slurm-and-partitions.md): TRES scheduling, partitions, GPU requests
6. [Snakemake 9+ workflows](06-snakemake.md): profiles, scratch working directories, migration from `cluster.yaml`
7. [Starting a new project](07-new-project.md): the setup scripts and templates in this repo
8. [Publishing these docs](08-publishing-docs.md): GitHub Pages options
9. [Reference data](09-references.md): referenceDB master on NFS, scratch mirror, staging rule
10. [Usernames and handles](10-user-names.md): username map, user directory naming, readable `ls`
11. [Group shell setup](11-shell-setup.md): shared `.bashrc` snippet, `umask`, shortcuts

Facts marked **VERIFY** have not been confirmed against GW documentation or on the cluster.

External references: [Pegasus](https://it.gwu.edu/hpc-pegasus), [hpc-onboarding](https://github.com/gwuniversity/hpc-onboarding), [legacy docs](https://github.com/gwcbi/HPC) (Colonial One era; verify before reusing), and the local copy of the *Pegasus Researcher Guide to Resource Allocation* (Rev B, updated 2026-02-27) in the repo root.
