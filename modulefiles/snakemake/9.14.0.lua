-- -*- lua -*-
-- Snakemake 9.14.0 (conda environment) for the Bendall group.
-- Install and maintenance: docs/apps/snakemake.md in the GWHPC-bendallgrp repository.
local version = "9.14.0"
local envdir  = pathJoin("/GWSPH/groups/bendallgrp/software/conda/envs", "snakemake-" .. version)

whatis("Name: Snakemake")
whatis("Version: " .. version)
whatis("URL: https://snakemake.readthedocs.io")
whatis("Description: Snakemake workflow manager with the SLURM executor plugin (shared conda environment)")

help([[
Snakemake 9 with snakemake-executor-plugin-slurm, from a read-only shared conda environment.
Run workflows with a profile (see a project's run.sh); cluster.yaml and --cluster are not supported.
Rules that use `conda:` also need `module load miniforge3`.
Documentation: docs/apps/snakemake.md and docs/06-snakemake.md in the GWHPC-bendallgrp repository.
]])

family("snakemake")
prepend_path("PATH", pathJoin(envdir, "bin"))
