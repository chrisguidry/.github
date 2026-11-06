# The provider has no resource for CodeQL's default setup, so
# code-scanning.sh reads this list after an apply and turns it on where it
# is off. Code scanning is free only on a public repository.
output "public_repositories" {
  description = "The public repositories, which code-scanning.sh checks"
  value       = sort(keys(local.public))
}
