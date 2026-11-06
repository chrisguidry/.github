#!/usr/bin/env bash
# Reports each public repository whose workflows run on a pull request
# from a fork without waiting for approval when the contributor has never
# contributed to it, and with --apply, makes them wait. The provider has no
# resource for this policy. A private repository has no forks outside its
# owner, so it is left as it is.
#
#   ./actions.sh [--apply]
#
# It reads Terraform's public_repositories output, so it needs the state of
# an apply, and gh signed in as the repositories' owner.

set -euo pipefail
cd "$(dirname "$0")"

policy=first_time_contributors
apply=false
[ "${1:-}" = --apply ] && apply=true

differs=0
for repository in $(terraform output -json public_repositories | jq -r '.[]'); do
    current=$(gh api "repos/chrisguidry/$repository/actions/permissions/fork-pr-contributor-approval" --jq .approval_policy)
    [ "$current" = "$policy" ] && continue
    differs=$((differs + 1))
    if $apply; then
        gh api --silent -X PUT "repos/chrisguidry/$repository/actions/permissions/fork-pr-contributor-approval" \
            -f approval_policy="$policy"
        echo "$repository: $current -> $policy"
    else
        echo "$repository: $current"
    fi
done

# A report that finds a repository different fails, so a scheduled run says so.
$apply || [ "$differs" -eq 0 ]
