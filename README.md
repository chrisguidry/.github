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
- A workflow's `GITHUB_TOKEN` only reads unless the workflow asks for
  more, and no workflow approves a pull request.  A pull request from a
  fork by someone who has never contributed waits for approval before its
  workflows run.
- main keeps a linear history that no one force-pushes or deletes.  A
  repository in the `pr` tier also takes changes only through a pull
  request whose `All checks passed` job succeeded.

[`images/`](images/README.md) holds the standard for a repository that
publishes a container image: the OCI keys it writes, and the bake file
that writes them.

A private repository gets the merge settings only, since GitHub's Free
plan gives it no rulesets and no secret scanning.

## Applying

The state is in a Linode Object Storage bucket (see `backend.tf`).

```
export AWS_ACCESS_KEY_ID=…      # the bucket's access key ID
export AWS_SECRET_ACCESS_KEY=…  # and its secret
export GITHUB_TOKEN=$(gh auth token)
terraform plan
terraform apply
./code-scanning.sh          # report each repository whose CodeQL is off
./code-scanning.sh --apply  # and turn it on
./actions.sh                # report each repository whose forks' pull requests run without approval
./actions.sh --apply        # and require it
```

A new entry in `repositories.yaml` creates its repository.  An entry for
a repository that already exists adopts it by import, and the plan fails
when GitHub has a repository that the file does not list.  Terraform
archives rather than deletes a repository dropped from the list.

## CI

A pull request plans, and a push to main applies, turns on any CodeQL
that is off, and requires approval for forks' pull requests where it is
not required.  A daily run fails when its plan has any change in it, or
when either script finds a repository to change, which catches a setting changed by hand, an
unlisted repository, and an expired token.  The workflow's secrets are
`SETTINGS_TOKEN`, a fine-grained token with Administration read and write
and Contents read on every repository, and `STATE_ACCESS_KEY_ID` and
`STATE_SECRET_ACCESS_KEY`, the bucket's access key.
