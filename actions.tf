# Each workflow's GITHUB_TOKEN can only read unless the workflow asks for
# more in its own permissions block, and no workflow approves a pull
# request, so a workflow that a pull request changes cannot merge it.

import {
  for_each = local.existing
  to       = github_workflow_repository_permissions.token[each.key]
  id       = each.key
}

resource "github_workflow_repository_permissions" "token" {
  for_each = local.repositories

  repository                       = github_repository.repository[each.key].name
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}

