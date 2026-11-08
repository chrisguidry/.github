# Container images

Every repository here that publishes a container image builds it with
`docker buildx bake` from a `docker-bake.hcl` at its root, and that file
writes the image's OCI keys
([`org.opencontainers.image.*`](https://github.com/opencontainers/image-spec/blob/main/annotations.md)).
[`docker-bake.hcl`](docker-bake.hcl) here is the reference copy.  Each
repository holds its own copy of its variables and its three functions,
word for word, so a build reads no file from outside its repository.

The keys live in the bake file and not in the Dockerfile for two
reasons.  A `LABEL` that changes on each commit would sit in the
Dockerfile's build graph, while a label from bake is copied into the
image config after the build, so it invalidates no layer cache.  And a
person who builds the Dockerfile in a fork gets no label that claims
the image is ours.  No Dockerfile has a `LABEL` or `MAINTAINER` line.

## What each image carries

| Key | Value |
|---|---|
| `source` | The repository's URL, from CI |
| `revision` | The full commit SHA, from CI |
| `version` | The version the workflow tags the image with, from CI |
| `created` | The commit's committer time in RFC 3339, `git log -1 --format=%cI` |
| `url` | The docs site, or the repository's page |
| `licenses` | The SPDX expression of the repository's LICENSE. A project of mine with no LICENSE gets the MIT license first |
| `vendor` | `Chris Guidry` |
| `title` | The image's name |
| `description` | One line saying what the image is |
| `documentation` | The most specific docs page for the image |

A local build leaves `source`, `revision`, `version`, and `created` out.
Every other key that is `""` is written as `""`, which replaces a label
of the same key that the base image set.  A config label passes into
every image built `FROM` it, so an image whose base sets an OCI key that
we do not use sets that key to `""`.

Each key is written twice: as a label in the image config, which
`docker inspect`, syft, and Trivy read, and as an annotation on the
image index and each image manifest, which ghcr.io reads for the
description of a multi-platform image.  A local `--load` exports no
index, and BuildKit refuses an index annotation there, so only a build
with `REVISION` set writes annotations.

## The CI step

CI sets the commit's values and pushes in one plain step, so the same
command runs on GitHub, on Tangled, and on a laptop:

```sh
export SOURCE="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY"
export REVISION="$GITHUB_SHA"
export VERSION="…"   # the version the workflow already computes
CREATED=$(git log -1 --format=%cI)
SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
export CREATED SOURCE_DATE_EPOCH
docker buildx bake --push --metadata-file "$RUNNER_TEMP/metadata.json"
```

`SOURCE_DATE_EPOCH` makes BuildKit write the commit's time, and not the
runner's clock, as the image config's `created` field, and it leaves the
layer cache as it is.  A push with attestations exports an image index,
which the index annotations need.  The metadata file holds the pushed
digest, for a step that signs or attests it.  A `type=gha` cache needs
the Actions runtime token, which a plain `run:` step does not receive,
so a workflow that uses it runs `crazy-max/ghaction-github-runtime`
first.

## Images built with `ko`

`ko` builds a Go program with no Dockerfile, so it does not read a bake
file.  A repository that builds with `ko` writes the same keys with
`ko build --image-label` and `--image-annotation` from a `ko-build.sh`
that CI and a person both run.  `ko` copies the base image's labels and
annotations into its result, so the script also writes every key that
the base sets, with `""` for each one the image does not use.  `ko`
splits each flag value at commas, so no value may hold one.
