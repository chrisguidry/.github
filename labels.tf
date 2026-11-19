# Every repository has a simmer label. The repository owner adds it to an
# issue or a pull request to hand that thread to the chrisguidry-simmer
# GitHub App's triage. Only the owner's use of it does anything.
#
# github_issue_label manages this one label and leaves the repository's
# other labels alone. The label does not exist yet, so it is created, not
# imported.

resource "github_issue_label" "simmer" {
  for_each = local.repositories

  repository  = github_repository.repository[each.key].name
  name        = "simmer"
  description = "Handed to the simmer bot for triage"
  color       = "d4a72c"
}
