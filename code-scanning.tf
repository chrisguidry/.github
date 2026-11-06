# The provider has no resource for CodeQL's default setup, so
# code-scanning.sh reads this list after an apply and turns it on where it
# is off. Code scanning is free only on a public repository.
output "default_code_scanning" {
  description = "The repositories whose CodeQL scanning is GitHub's default setup"
  value       = sort([for name, repository in local.public : name if repository.code_scanning == "default"])
}
