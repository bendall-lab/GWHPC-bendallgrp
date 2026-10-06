# <Tool>

- **What it is:** one line, with the homepage URL
- **Module:** `<tool>/<version>`
- **Install tree:** `/GWSPH/groups/bendallgrp/software/<tool>/<version>`
- **Modulefile:** `modulefiles/<tool>/<version>.lua` in this repository, published to `/GWSPH/groups/bendallgrp/software/modulefiles/<tool>/<version>.lua`
- **Maintainer:**

## Using it

```bash
module load <tool>/<version>
<tool> --version
```

Caveats a user should know (conflicts with other modules, required resources, known issues).

## Install <version>

Run on a Pegasus login node as the admin. Nothing here is run by members.

```bash
cd /GWSPH/groups/bendallgrp/software
mkdir -p <tool>/archive && cd <tool>/archive
wget <download url>
wget <checksum url>
sha256sum -c <checksum file>      # or md5sum -c; must say OK before continuing
cd ..
# unpack or build into <tool>/<version>/ here
chmod -R go-w <version>           # read-only for members
```

## Modulefile

Copy `templates/modulefiles/tool.lua`, fill in the placeholders, and commit it as `modulefiles/<tool>/<version>.lua` in this repository. Then publish it on the cluster:

```bash
cd /GWSPH/groups/bendallgrp/software/tools/GWHPC-bendallgrp.git && git pull
scripts/install-modulefiles.sh --dry-run
scripts/install-modulefiles.sh
```

## Verify

```bash
module load <tool>/<version>
<tool> --version
module help <tool>/<version>
```

## Changelog

| Date | Version | Change |
|---|---|---|
| YYYY-MM-DD | <version> | initial install |
