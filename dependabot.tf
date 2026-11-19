# Dependabot alerts on every repository's vulnerable dependencies, the
# pull requests that update them, and the .github/dependabot.yml that
# keeps the rest of its dependencies current.

import {
  for_each = local.existing
  to       = github_repository_vulnerability_alerts.alerts[each.key]
  id       = each.key
}

resource "github_repository_vulnerability_alerts" "alerts" {
  for_each = local.repositories

  repository = github_repository.repository[each.key].name
  enabled    = true
}

import {
  for_each = local.existing
  to       = github_repository_dependabot_security_updates.updates[each.key]
  id       = each.key
}

resource "github_repository_dependabot_security_updates" "updates" {
  for_each = local.repositories

  repository = github_repository_vulnerability_alerts.alerts[each.key].repository
  enabled    = true
}

# Each repository's .github/dependabot.yml comes from one template, so
# every repository updates on the same schedule with the same grouping and
# the same wait after a release. A repository's entry in repositories.yaml
# names only its ecosystems and what it ignores. A repository with
# dependabot: false gets no file.
#
# A uv entry must also say whether the project is a library or an
# application, because Dependabot's own guess raises a library's
# requirements. Whoever installs a library resolves its requirements
# against their own, so each one stays as low as the library supports,
# and only uv.lock moves. Nobody resolves against an application, so its
# requirements follow the versions it is tested with. A uv entry with no
# project, or an unknown one, fails the plan.
locals {
  uv_versioning = {
    library     = "lockfile-only"
    application = "increase"
  }

  dependabot_updates = {
    for name, repository in local.repositories : name => concat(
      [{ ecosystem = "github-actions", directories = ["/"], versioning = null, ignore = [] }],
      [
        for update in repository.dependabot : {
          ecosystem   = update.ecosystem
          directories = try(update.directories, ["/"])
          versioning  = update.ecosystem == "uv" ? local.uv_versioning[update.project] : null
          ignore = [
            for ignored in try(update.ignore, []) : {
              dependency = ignored.dependency
              versions   = try(ignored.versions, null)
              reason     = ignored.reason
            }
          ]
        }
      ],
    ) if repository.dependabot != false
  }
}

# The commit goes straight to main as the chrisguidry-settings GitHub App,
# which the main checks ruleset lets through, so that ruleset comes first.
# The file replaces one that the repository already has.
resource "github_repository_file" "dependabot" {
  for_each = local.dependabot_updates

  repository          = github_repository.repository[each.key].name
  file                = ".github/dependabot.yml"
  content             = templatefile("${path.module}/dependabot.yml.tftpl", { updates = local.dependabot_updates[each.key] })
  commit_message      = "Write dependabot.yml from chrisguidry/.github"
  overwrite_on_create = true

  depends_on = [github_repository_ruleset.main, github_repository_ruleset.main_checks]
}
