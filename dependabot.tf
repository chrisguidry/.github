# Dependabot alerts on every repository's vulnerable dependencies, and the
# pull requests that update them.

import {
  for_each = local.repositories
  to       = github_repository_vulnerability_alerts.alerts[each.key]
  id       = each.key
}

resource "github_repository_vulnerability_alerts" "alerts" {
  for_each = local.repositories

  repository = github_repository.repository[each.key].name
  enabled    = true
}

import {
  for_each = local.repositories
  to       = github_repository_dependabot_security_updates.updates[each.key]
  id       = each.key
}

resource "github_repository_dependabot_security_updates" "updates" {
  for_each = local.repositories

  repository = github_repository_vulnerability_alerts.alerts[each.key].repository
  enabled    = true
}
