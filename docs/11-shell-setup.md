# 11. Group shell setup

`scripts/group-bashrc.sh` gives every member the same shell environment: group-friendly `umask`, path variables, shortcuts, and the handle-aware wrappers from [Usernames and handles](10-user-names.md). It is sourced from each member's own `~/.bashrc`, so it is opt-in and easy to remove.

## Install (each member, once)

The admin has already published the scripts into `local/` ([Starting a new project](07-new-project.md#where-this-repo-lives-on-the-cluster)). Members then run:

```bash
/GWSPH/groups/bendallgrp/local/bin/install-shell-setup.sh --dry-run   # preview
/GWSPH/groups/bendallgrp/local/bin/install-shell-setup.sh
source ~/.bashrc
```

It appends this block to `~/.bashrc`, once; re-running does nothing. The path is stable (a symlink into the repo), so repo updates never require reinstalling:

```bash
# >>> bendallgrp shell setup >>>
[ -r ".../local/etc/group-bashrc.sh" ] && . ".../local/etc/group-bashrc.sh"
# <<< bendallgrp shell setup <<<
```

To remove it, delete those three lines. If your login shell reads `~/.bash_profile` and not `~/.bashrc`, make sure `.bash_profile` sources `.bashrc` (**VERIFY** on Pegasus login nodes).

## What it sets

| Item | Value |
|---|---|
| `umask 002` | files you create are group-writable (directories already inherit the group via setgid) |
| `BENDALLGRP_ROOT` | `/GWSPH/groups/bendallgrp` |
| `BENDALLGRP_SCRATCH` | `/scratch/bendallgrp` |
| `BENDALLGRP_LOCAL`, `BENDALLGRP_TOOLS` | `local/` and the repo checkout |
| `BENDALLGRP_HOME`, `BENDALLGRP_SCRATCH_HOME` | your personal directories, via the `users/.<linux_user>` dot-links |
| `PATH` | `local/bin` appended, so `init-user.sh`, `new-project.sh`, `sync-references.sh` etc. run from anywhere |

Interactive shells also get:

| Command | Does |
|---|---|
| `cdg`, `cds` | go to the group directory, group scratch |
| `cdme`, `cdsme` | go to your directory on NFS, on scratch |
| `cdproj`, `cdref` | go to `projects/`, the refDB master |
| `lsh`, `sqh`, `hpc_filter`, `hpc_whoami` | show handles instead of Linux usernames |
| `user-map-lookup NAME`, `user-map-list` | look up a handle or username; print the whole map |
| `qstat` | your queued and running jobs (job id, name, state, elapsed time, partition, start, reason) |
| `qcheck [-j IDS]` | your recent job history (`sacct` with state, partition, start, end, nodes) |
| `qstate JOBID` | one job's state, lowercase, for scripts |

`HPC_WRAP_LS=1` (set before the group block in `~/.bashrc`) additionally makes plain `ls` show handles in long listings; see [Usernames and handles](10-user-names.md).

Interactive shells also:

- load the `slurm`, `git` and `curl` modules, but only if `sbatch`, `git` or `curl` isn't already on `PATH`;
- set `LMOD_COLORIZE=YES`;
- set `TMPDIR=/local` when `/local` is writable and `TMPDIR` is unset or `/tmp`. A `TMPDIR` that Slurm sets for a job is never overridden. Jobs share `/local`, so create a private directory with `mktemp -d -p "$TMPDIR"` and remove it when the job ends.

Only `umask` and the environment variables are set in non-interactive shells (for example batch jobs that source `~/.bashrc`); aliases and functions are interactive-only.

## Changing it

Edit `scripts/group-bashrc.sh` in the repo and update the permanent checkout with `git pull`; everyone gets the change at their next login. Keep it small and free of anything that prints output or can fail, because a broken line affects every member's shell.

## What is deliberately not included

- **Conda initialization.** Use the cluster's own setup; the shared environment layout is in [Conda and software](04-conda.md).
- **A conda package cache setting.** That decision is still open (see the same page).
- **Compiler and other module loads** (for example `gcc`). Load what a job needs in the job script or workflow, and pin versions there.

## Optional personal setup

The group file deliberately leaves prompts and editing features to each member. Everything below installs in your home directory without root; check each tool against your own needs. Because zsh is not an available login shell, these bring some of the zsh/Oh My Zsh experience to bash.

- **Guard interactive-only settings.** Wrap prompts, module loads and aliases in `case $- in *i*) ... esac` (or `[[ $- == *i* ]] || return` after the environment settings), so batch jobs and `scp`/`rsync` sessions that read `~/.bashrc` stay fast and silent.
- **Better history and shell options:**

  ```bash
  HISTSIZE=50000; HISTFILESIZE=100000
  HISTCONTROL=ignoreboth:erasedups
  shopt -s histappend cmdhist checkwinsize cdspell autocd globstar
  PROMPT_COMMAND='history -a'      # keep history across multiple login sessions
  ```

- **[Oh My Bash](https://github.com/ohmybash/oh-my-bash):** the bash counterpart of Oh My Zsh, with themes and plugins. The installer backs up your `~/.bashrc`; set `OSH` to choose a custom install directory and `OMB_USE_SUDO=false` since you don't have root.
- **[starship](https://starship.rs/):** a fast prompt that works in bash. Install with the script's `-b` option into `~/.local/bin`, then add `eval "$(starship init bash)"` to `~/.bashrc`. A prompt that runs `git status` in a huge repository on NFS or scratch can lag, so use starship's `command_timeout` setting or disable the git module for those paths.
- **[fzf](https://github.com/junegunn/fzf) and [zoxide](https://github.com/ajeetdsouza/zoxide):** fuzzy `Ctrl-R` history search and a `z`-style directory jumper. Source fzf's bash key bindings in `~/.bashrc`; initialize zoxide with `eval "$(zoxide init bash)"` as the last line.
- **[ble.sh](https://github.com/akinomyoga/ble.sh):** zsh/fish-style autosuggestions and syntax highlighting for bash itself (bash 4.0 or newer recommended). Source it near the top of `~/.bashrc` and attach it at the end.
- **`tmux`:** keep long-running sessions, such as a Snakemake `run.sh`, alive on a login node. **VERIFY** that `tmux` or `screen` is available on Pegasus (or install it under `~/.local`).
