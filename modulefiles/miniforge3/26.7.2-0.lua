-- -*- lua -*-
-- Miniforge3 26.7.2-0 for the Bendall group.
-- Install and maintenance: docs/apps/miniforge3.md in the GWHPC-bendallgrp repository.
local version = "26.7.2-0"
local prefix  = pathJoin("/GWSPH/groups/bendallgrp/software/miniforge3", version)
local funcs   = "conda __conda_activate __conda_hashr __conda_reactivate"

whatis("Name: Miniforge3")
whatis("Version: " .. version)
whatis("Description: conda and mamba with conda-forge and bioconda; no Anaconda defaults channel")
help([[
Miniforge3 (conda and mamba). Group defaults come from the .condarc in the install prefix.
Personal environments go in ~/.conda/envs; shared group environments are read-only.
Documentation: docs/apps/miniforge3.md in the GWHPC-bendallgrp repository.
]])

-- Only one conda may be loaded at a time (blocks e.g. the RTS miniconda module).
family("python")
conflict("anaconda", "miniconda", "miniconda3")

execute{cmd=". " .. prefix .. "/etc/profile.d/conda.sh; export -f " .. funcs, modeA={"load"}}
-- Activate base so conda's own prompt prefix "(base)" appears while the module is loaded.
-- The unload code below deactivates it again and restores the prompt.
execute{cmd="conda activate base", modeA={"load"}}
execute{cmd="for i in $(seq ${CONDA_SHLVL:-0}); do conda deactivate; done; "
         .. "export PATH=$(echo \"$PATH\" | tr ':' '\\n' | grep -v '^" .. prefix .. "' | paste -sd: -); "
         .. "unset -f " .. funcs .. "; "
         .. "unset CONDA_EXE CONDA_PYTHON_EXE CONDA_SHLVL _CE_CONDA _CE_M",
        modeA={"unload"}}
