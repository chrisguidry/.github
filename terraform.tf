# The settings of every repository under github.com/chrisguidry, applied
# with the token in GITHUB_TOKEN. repositories.yaml lists the
# repositories and what each one sets beyond the standard.

terraform {
  required_version = ">= 1.10"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

provider "github" {
  owner = "chrisguidry"
}
