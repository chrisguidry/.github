# One ruleset per public repository, named main, on its default branch.
# Every repository keeps a linear history that no one rewrites or deletes.
# A repository in the pr tier also takes changes only through a pull
# request whose "All checks passed" job succeeded. That job lists the
# repository's other jobs in its needs, so the repository decides what
# passing means, and this ruleset never changes when its CI does.

locals {
  # The rulesets that predate this configuration, adopted in place.
  adopted_rulesets = {
    docket       = 3865298
    uncalled-for = 13243149
  }

  # The GitHub Actions app, so only a workflow can report the check.
  github_actions = 15368
}

import {
  for_each = local.adopted_rulesets
  to       = github_repository_ruleset.main[each.key]
  id       = "${each.key}:${each.value}"
}

resource "github_repository_ruleset" "main" {
  for_each = local.public

  name        = "main"
  repository  = github_repository.repository[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    dynamic "pull_request" {
      for_each = each.value.tier == "pr" ? [1] : []
      content {
        allowed_merge_methods = ["squash", "rebase"]
      }
    }

    dynamic "required_status_checks" {
      for_each = each.value.tier == "pr" ? [1] : []
      content {
        required_check {
          context        = "All checks passed"
          integration_id = local.github_actions
        }
        dynamic "required_check" {
          for_each = each.value.extra_checks
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}
