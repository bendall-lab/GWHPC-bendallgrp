#!/usr/bin/env bash
# Publish the user-facing scripts by symlinking them from local/ into this checkout.
#   local/bin/<script>.sh  -> <checkout>/scripts/<script>.sh   (executables, on members' PATH)
#   local/etc/<file>.sh    -> <checkout>/scripts/<file>.sh     (files members source)
# Idempotent. Run by the group admin from the permanent checkout
# ($GROUP_ROOT/software/tools/GWHPC-bendallgrp.git) after adding or renaming a script.
# `git pull` in the checkout updates what members run; there is no separate deploy step.
#
# Usage: link-local.sh [-n|--dry-run]
set -euo pipefail
# Resolve symlinks so the script works when run via local/bin/ (see docs/02-directory-layout.md)
SCRIPT_DIR="$(cd -P "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
parse_common_flags "$@"

BIN_SCRIPTS=(init-user.sh new-project.sh user-map.sh sync-references.sh check-node-storage.sh install-shell-setup.sh)
ETC_SCRIPTS=(group-bashrc.sh hpc-aliases.sh)

expected="$GROUP_ROOT/software/tools/GWHPC-bendallgrp.git"
[[ "$(cd -P "$SCRIPT_DIR/.." && pwd)" == "$(cd -P "$expected" 2>/dev/null && pwd || echo "$expected")" ]] ||
    warn "this checkout is not at $expected; links will point at $SCRIPT_DIR instead"

check_root "$GROUP_ROOT"
make_dir "$LOCAL_ROOT"     2755
make_dir "$LOCAL_ROOT/bin" 2755
make_dir "$LOCAL_ROOT/etc" 2755

link() {   # link TARGET_DIR NAME
    local dir="$1" name="$2" src="$SCRIPT_DIR/$2"
    [[ -f "$src" ]] || die "missing script: $src"
    run ln -sfn "$src" "$dir/$name"
}

for s in "${BIN_SCRIPTS[@]}"; do link "$LOCAL_ROOT/bin" "$s"; done
for s in "${ETC_SCRIPTS[@]}"; do link "$LOCAL_ROOT/etc" "$s"; done

info "Linked ${#BIN_SCRIPTS[@]} scripts into $LOCAL_ROOT/bin and ${#ETC_SCRIPTS[@]} into $LOCAL_ROOT/etc"
