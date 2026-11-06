# chrisguidry/.github

The settings of every repository under github.com/chrisguidry that is
neither a fork nor archived, managed with Terraform.

[`repositories.yaml`](repositories.yaml) lists the repositories and what
each one sets beyond the standard.  The standard is:

- Pull requests merge by squash, titled and described by the pull request,
  or by rebase, and never with a merge commit.  A merged branch is deleted.
- Dependabot alerts and security updates, secret scanning, and push
  protection are on.  CodeQL's default setup is on, unless the repository
  runs CodeQL from a workflow of its own.
- main keeps a linear history that no one force-pushes or deletes.  A
  repository in the `pr` tier also takes changes only through a pull
  request whose `All checks passed` job succeeded.

A private repository gets the merge settings only, since GitHub's Free
plan gives it no rulesets and no secret scanning.

## Applying

```
GITHUB_TOKEN=$(gh auth token) terraform plan
GITHUB_TOKEN=$(gh auth token) terraform apply
./code-scanning.sh          # report each repository whose CodeQL is off
./code-scanning.sh --apply  # and turn it on
```

A new entry in `repositories.yaml` creates its repository.  An entry for
a repository that already exists adopts it by import, and the plan fails
when GitHub has a repository that the file does not list.  Terraform
archives rather than deletes a repository dropped from the list.
