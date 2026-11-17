# One ruleset per public repository, named main, on its default branch.
# Every repository keeps a linear history that no one rewrites or deletes.
# A repository in the pr tier also takes changes only through a pull
# request whose "All checks passed" job succeeded. That job lists the
# repository's other jobs in its needs, so the repository decides what
# passing means, and this ruleset never changes when its CI does.
#
# A repository in the checks tier gets a second ruleset, named main
# checks, that requires the same job and that the repository's admins
# bypass. The admins still push straight to main, and a pull request that
# anything else merges, such as one with auto-merge on, waits for the job.
# The bypass is in a ruleset of its own so that it does not also lift the
# rules on main's history.

locals {
  # The GitHub Actions app, so only a workflow can report the check.
  github_actions = 15368
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

resource "github_repository_ruleset" "main_checks" {
  for_each = { for name, repository in local.public : name => repository if repository.tier == "checks" }

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
    actor_id    = local.repository_admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
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
