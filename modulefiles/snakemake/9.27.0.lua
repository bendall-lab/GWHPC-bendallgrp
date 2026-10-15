-- -*- lua -*-
-- Snakemake 9.27.0 (pixi environment) for the Bendall group.
-- Install and maintenance: docs/apps/snakemake.md in the GWHPC-bendallgrp repository.
local version = "9.27.0"
local envdir  = pathJoin("/GWSPH/groups/bendallgrp/software/snakemake", version, ".pixi/envs/default")

whatis("Name: Snakemake")
whatis("Version: " .. version)
whatis("URL: https://snakemake.readthedocs.io")
whatis("Description: Snakemake workflow manager with the SLURM executor plugin, conda and mamba (shared pixi environment)")

help([[
Snakemake 9 with snakemake-executor-plugin-slurm, conda and mamba, from a read-only shared pixi environment.
Run workflows with a profile (see a project's run.sh); cluster.yaml and --cluster are not supported.
Rules with a `conda:` directive work with --software-deployment-method conda; no other module is needed.
Documentation: docs/apps/snakemake.md and docs/06-snakemake.md in the GWHPC-bendallgrp repository.
]])

family("snakemake")
prepend_path("PATH", pathJoin(envdir, "bin"))
