# Pixi

- **What it is:** Pixi, a package and environment manager built on the conda ecosystem (project-based, `pixi.toml` and `pixi.lock`), https://pixi.sh
- **Module:** `pixi/<version>`
- **Install tree:** `/GWSPH/groups/bendallgrp/software/pixi/<version>` (a single static binary at `bin/pixi`)
- **Modulefile:** `modulefiles/pixi/<version>.lua` in this repository, published to `/GWSPH/groups/bendallgrp/software/modulefiles/pixi/<version>.lua`
- **Maintainer:** group admin

The version in the committed modulefile (`0.55.0`) and in the commands below is a placeholder: **VERIFY** the current release at https://github.com/prefix-dev/pixi/releases and keep the install directory, modulefile name, its `version` and `.modulerc.lua` identical.

## Using it

```bash
module load pixi
pixi --version
pixi init myproject && cd myproject
pixi add python
pixi run python --version
```

Caveats:

- Pixi environments live in the project (`.pixi/` next to `pixi.toml`), so keep projects off the home directory if they are large. Package downloads are cached under `~/.cache/rattler`; point it elsewhere with `export PIXI_CACHE_DIR=...` if home space is tight. **VERIFY** the variable name against `pixi info` on the cluster.
- `pixi global install` writes under `~/.pixi` (`PIXI_HOME`), per user; the group install is not touched.
- Pixi does not need `miniforge3` and does not conflict with it, but do not mix the two in one shell session.
- Do not run `pixi self-update`: the install is read-only, and new versions are installed by the admin.
- Unlike the `snakemake` module, nothing about pixi is wired into `new-project.sh` or `run.sh`.

## Install <version>

Run on a Pegasus login node as the admin. Nothing here is run by members.

```bash
umask 0022
G=/GWSPH/groups/bendallgrp
PIXI="0.55.0"                     # VERIFY: current release
mkdir -p $G/software/pixi/archive $G/software/modulefiles/pixi
chmod 2755 $G/software/pixi $G/software/modulefiles/pixi

cd $G/software/pixi/archive
URL=https://github.com/prefix-dev/pixi/releases/download/v$PIXI
wget $URL/pixi-x86_64-unknown-linux-musl.tar.gz
wget $URL/pixi-x86_64-unknown-linux-musl.tar.gz.sha256
sha256sum -c pixi-x86_64-unknown-linux-musl.tar.gz.sha256      # must print: ...: OK
```

Confirm the exact asset names on the release page; the pattern above is the usual one. If the `.sha256` file contains only the hash (no file name), check with `echo "$(cat pixi-x86_64-unknown-linux-musl.tar.gz.sha256)  pixi-x86_64-unknown-linux-musl.tar.gz" | sha256sum -c`.

Unpack into the versioned prefix and make it read-only:

```bash
mkdir -p $G/software/pixi/$PIXI/bin
tar -xzf pixi-x86_64-unknown-linux-musl.tar.gz -C $G/software/pixi/$PIXI/bin pixi
chmod -R go-w $G/software/pixi/$PIXI
$G/software/pixi/$PIXI/bin/pixi --version
```

## Modulefile

Committed as `modulefiles/pixi/<version>.lua` (and `.modulerc.lua` for the default), then published:

```bash
cd $G/software/tools/GWHPC-bendallgrp.git && git pull
scripts/install-modulefiles.sh --dry-run
scripts/install-modulefiles.sh
```

## Verify

```bash
module use $G/software/modulefiles
module avail pixi
module load pixi
which pixi && pixi --version
module help pixi
module unload pixi
```

As a member (not the admin), also run `pixi init /tmp/pixi-test && cd /tmp/pixi-test && pixi add python` to confirm that a normal user can create an environment, then delete the directory.

## Upgrading

Never modify an installed version. Repeat the install with the new version (new prefix), copy `modulefiles/pixi/<old>.lua` to `<new>.lua`, change `version`, move the default in `.modulerc.lua`, commit, pull on the cluster and publish. Keep older versions until nothing depends on them.

## Changelog

| Date | Version | Change |
|---|---|---|
| YYYY-MM-DD | <version> | initial install |
