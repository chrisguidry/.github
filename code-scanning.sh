#!/usr/bin/env bash
# Reports each repository in Terraform's default_code_scanning output whose
# CodeQL default setup is off, and with --apply, turns it on. GitHub picks
# the languages to scan from the repository's code.
#
#   ./code-scanning.sh [--apply]
#
# It needs the state of an apply, and gh signed in as the repositories'
# owner.

set -euo pipefail
cd "$(dirname "$0")"

apply=false
[ "${1:-}" = --apply ] && apply=true

off=0
for repository in $(terraform output -json default_code_scanning | jq -r '.[]'); do
    state=$(gh api "repos/chrisguidry/$repository/code-scanning/default-setup" --jq .state)
    [ "$state" = configured ] && continue
    off=$((off + 1))
    if $apply; then
        gh api --silent -X PATCH "repos/chrisguidry/$repository/code-scanning/default-setup" \
            -f state=configured -f query_suite=default
        echo "$repository: turned on"
    else
        echo "$repository: $state"
    fi
done

# A report that finds a repository off fails, so a scheduled run says so.
$apply || [ "$off" -eq 0 ]
