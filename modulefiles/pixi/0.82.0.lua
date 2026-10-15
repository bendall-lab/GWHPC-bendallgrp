-- -*- lua -*-
-- Pixi 0.82.0 for the Bendall group.
-- Install and maintenance: docs/apps/pixi.md in the GWHPC-bendallgrp repository.
local version = "0.82.0"
local base    = pathJoin("/GWSPH/groups/bendallgrp/software/pixi", version)

whatis("Name: Pixi")
whatis("Version: " .. version)
whatis("URL: https://pixi.sh")
whatis("Description: Package and environment manager built on the conda ecosystem")

help([[
Pixi: project-based package manager using conda-forge packages (pixi.toml / pixi.lock).
Pixi's package cache defaults to ~/.cache/rattler; set PIXI_CACHE_DIR if home space is tight.
Documentation: docs/apps/pixi.md in the GWHPC-bendallgrp repository.
]])

prepend_path("PATH", pathJoin(base, "bin"))
