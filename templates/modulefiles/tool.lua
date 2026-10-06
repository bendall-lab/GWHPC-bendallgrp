-- -*- lua -*-
-- Template for a group modulefile. Install steps do NOT go here: see docs/apps/<tool>.md
local name    = "@TOOL@"
local version = "@VERSION@"
local base    = pathJoin("/GWSPH/groups/bendallgrp/software", name, version)

whatis("Name: " .. name)
whatis("Version: " .. version)
whatis("URL: @URL@")
whatis("Description: @ONE_LINE_DESCRIPTION@")

help([[
@TOOL@ @VERSION@: @ONE_LINE_DESCRIPTION@
Usage: @TOOL@ --help
Homepage: @URL@
Install notes: docs/apps/@TOOL@.md in the GWHPC-bendallgrp repository.
]])

prepend_path("PATH", pathJoin(base, "bin"))
