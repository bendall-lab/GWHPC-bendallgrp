# Group-installed apps

One page per application installed under `software/` and published as an Lmod module. These pages are the source of truth for **how an app was installed**; the modulefile itself stays short ([convention below](#modulefile-conventions)).

| App | Module | Install tree | Page |
|---|---|---|---|
| Miniforge | `miniforge3/<version>` | `software/miniforge3/<version>` | [Admin setup: app installs](../setup-admin-apps.md) (for now) |

Add a row whenever you add an app. Start a new page from `templates/app-doc.md` in the repo and name it `docs/apps/<tool>.md`, one page per tool with a section per version.

## Layout on the cluster

```text
/GWSPH/groups/bendallgrp/software/
├── <tool>/<version>/            # the install, read-only for members
├── <tool>/archive/              # downloaded installers/tarballs and their checksums
└── modulefiles/<tool>/<version>.lua
```

## Modulefile conventions

- **`whatis`**: name, version, homepage URL, one-line description (`module whatis` and `module avail` show these).
- **`help`**: three to six lines for the *user*: what it is, how to run it, caveats, and a link to the app's page here. No install commands.
- **Environment changes**: `prepend_path`/`setenv` only. Avoid `capture()` and `execute{}` unless the tool cannot work without them; each one starts a subprocess every time the module loads and every time the Lmod cache is rebuilt.
- Start from `templates/modulefiles/tool.lua` in the repo.
- Install steps, checksums, build flags, and the date and person that installed it go on the app's page, not in the modulefile.
