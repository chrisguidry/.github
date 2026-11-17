# One ruleset per public repository, named tags, on every tag. Only the
# repository's admins and GitHub Actions create, move, or delete a tag, so
# a token that can push a branch cannot cut a release. transom's android
# workflow creates its release tag with gh and the workflow's token, and
# docket publishes when a release is created.

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

  bypass_actors {
    actor_id    = local.github_actions
    actor_type  = "Integration"
    bypass_mode = "always"
  }

  rules {
    creation = true
    update   = true
    deletion = true
  }
}
