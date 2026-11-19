# One ruleset per public repository, named main, on its default branch.
# Every repository keeps a linear history that no one rewrites or deletes.
#
# A repository in the pr or the checks tier gets a second ruleset, named
# main checks, that requires the repository's "All checks passed" job.
# That job lists the repository's other jobs in its needs, so the
# repository decides what passing means, and this ruleset never changes
# when its CI does. In the pr tier the ruleset also requires a pull
# request. In the checks tier the repository's admins bypass it, so they
# still push straight to main, and a pull request that anything else
# merges, such as one with auto-merge on, waits for the job.
#
# The chrisguidry-settings GitHub App bypasses main checks in both tiers,
# because Terraform commits each repository's dependabot.yml to main as
# that App. The bypasses are in a ruleset of their own so that they do not
# also lift the rules on main's history.

locals {
  # The GitHub Actions app, so only a workflow can report the check.
  github_actions = 15368
}

variable "settings_app_id" {
  description = "The App ID of the chrisguidry-settings GitHub App, which commits each repository's dependabot.yml"
  type        = number
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
  }
}

resource "github_repository_ruleset" "main_checks" {
  for_each = { for name, repository in local.public : name => repository if repository.tier != "push" }

  name        = "main checks"
  repository  = github_repository.repository[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = var.settings_app_id
    actor_type  = "Integration"
    bypass_mode = "always"
  }

  dynamic "bypass_actors" {
    for_each = each.value.tier == "checks" ? [1] : []
    content {
      actor_id    = local.repository_admin
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }

  rules {
    dynamic "pull_request" {
      for_each = each.value.tier == "pr" ? [1] : []
      content {
        allowed_merge_methods = ["squash", "rebase"]
      }
    }

    required_status_checks {
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
