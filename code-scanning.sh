#!/usr/bin/env bash
# Reports each public repository whose CodeQL default setup is off, and
# with --apply, turns it on. A repository that runs CodeQL from a workflow
# of its own, as one whose code must be built while CodeQL watches does,
# keeps that workflow, and one with no code GitHub can scan is left as it
# is.
#
#   ./code-scanning.sh [--apply]
#
# It reads Terraform's public_repositories output, so it needs the state of
# an apply, and gh signed in as the repositories' owner.

set -euo pipefail
cd "$(dirname "$0")"

apply=false
[ "${1:-}" = --apply ] && apply=true

# Whether a workflow of the repository's own runs CodeQL's analysis.
scans_itself() {
    local paths path
    # A repository with no workflows answers 404, and so has none of its own.
    paths=$(gh api "repos/chrisguidry/$1/contents/.github/workflows" --jq '.[].path' 2>/dev/null) || return 1
    for path in $paths; do
        if gh api "repos/chrisguidry/$1/contents/$path" -H "Accept: application/vnd.github.raw" |
            grep -q 'github/codeql-action/analyze'; then
            return 0
        fi
    done
    return 1
}

off=0
for repository in $(terraform output -json public_repositories | jq -r '.[]'); do
    read -r state languages < <(gh api "repos/chrisguidry/$repository/code-scanning/default-setup" \
        --jq '"\(.state) \(.languages | length)"')
    [ "$state" = configured ] && continue
    [ "$languages" -eq 0 ] && continue
    scans_itself "$repository" && continue
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
