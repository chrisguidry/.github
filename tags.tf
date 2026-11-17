# One ruleset per public repository, named tags, on every tag. Only the
# repository's admins create, move, or delete a tag, so a token that can
# push a branch cannot cut a release, and docket publishes when a release
# is created.
#
# GitHub refuses the GitHub Actions app as a bypass actor, so a workflow's
# token cannot be let through by name.
# A repository with workflow_tags lets anyone who can push create a tag,
# and still keeps moving and deleting one to the admins.

locals {
  # The repository role whose members bypass a ruleset.
  repository_admin = 5
}

resource "github_repository_ruleset" "tags" {
  for_each = local.public

  name        = "tags"
  repository  = github_repository.repository[each.key].name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = local.repository_admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    creation = !each.value.workflow_tags
    update   = true
    deletion = true
  }
}
