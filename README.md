# <img src="https://raw.githubusercontent.com/ystorian/workflows/main/workflows.svg" width="48" align="absmiddle" alt="Workflows logo"> Workflows

Reusable GitHub Actions workflows for Ystorian repositories.

This is a public repository licensed under the [GNU Affero General Public License v3.0](LICENSE).

## Available workflows

CI:
- [Detect changes](#detect-changes) Detect relevant file changes to skip unneeded jobs
	- [Check](#check) Check actions and source code
	- [Cargo cache cleanup](#cargo-cache-cleanup) Delete superseded Cargo caches
- [Status check](#status-check) Set the required status check branch protection

Deployment:
- [Detect changes](#detect-changes) Detect relevant file changes to skip unneeded jobs
- [Build image](#build-image) Build and push a Docker image
- [Dispatch to Ynfra](#dispatch-to-ynfra) Send a dispatch event

## Detect changes

The `detect_changes.yaml` workflow detects relevant file changes with
[`dorny/paths-filter`](https://github.com/dorny/paths-filter).
It reads the `.github/filters.yaml` file of the calling repository.

- On push: the `run` output is the result of the `filter` input.
- On other events: the `run` output is always `true`.

```yaml
jobs:
  changes:
    name: Workflows
    uses: ystorian/workflows/.github/workflows/detect_changes.yaml@main
    permissions:
      contents: read
    with:
      filter: ci # Optional, default is `ci`.

  test:
    needs: changes
    if: needs.changes.outputs.run == 'true'
```

## Status check

The `status_check.yaml` workflow gives one required status check for a workflow.
It fails when a job in `needs` failed or was canceled.
Skipped jobs pass.

```yaml
jobs:
  status:
    name: Workflows
    needs: [changes, check, test]
    if: always()
    uses: ystorian/workflows/.github/workflows/status_check.yaml@main
    with:
      needs: ${{ toJSON(needs) }}
```

In branch protection, require only `Workflows / Status check`.

## Check

The `check.yaml` workflow checks a repository on Linux arm64. It checks Just recipes, typos, and
actions. More recipes can be added to check for Rust dependencies and other lints.

The caller must have the Just recipes `check_just`, `check_typos`, `check_actions`, and
`audit_actions`.

On failure, it cancels the whole workflow run.

```yaml
jobs:
  check:
    name: Workflows
    needs: changes
    if: needs.changes.outputs.run == 'true'
    uses: ystorian/workflows/.github/workflows/check.yaml@main
    permissions:
      actions: write # Required to cancel the `test` jobs on failure.
      contents: read
    with:
      tools: flynt # Comma separated optional tools to install.
      recipes: check_rust flynt # Space separated optional Just recipes to run.
      timeout: 1 # Optional, default is `1`.
```

The `recipes` input does not install tools. Add the tools of the recipes to `tools`.
For example, `check_deny` needs `tools: cargo-deny`.

## Cargo cache cleanup

The `cargo_cache_cleanup.yaml` workflow deletes the superseded Cargo caches of the current ref.
It keeps the newest cache for each group of key fields.

The cache keys must look like `cargo-<os>-<arch>-<rustc>-<lock>[-<run_id>]`.
The default group is the first 4 fields: `cargo-<os>-<arch>-<rustc>`.

```yaml
jobs:
  cargo-cache-cleanup:
    name: Workflows
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: ystorian/workflows/.github/workflows/cargo_cache_cleanup.yaml@main
    permissions:
      actions: write # Required to list and delete the cache entries.
    with:
      fields: 4 # Optional, default is `4`.
```

## Build image

The `build_image.yaml` workflow builds a Docker image and pushes it to `ghcr.io/<owner>/<image>`.
It gives the commit ID to the build with the `COMMIT_ID` build argument.
It keeps the build cache in the `buildcache` tag.

```yaml
jobs:
  build:
    name: Workflows
    needs: changes
    if: needs.changes.outputs.run == 'true'
    uses: ystorian/workflows/.github/workflows/build_image.yaml@main
    permissions:
      contents: read
      packages: write # Required to push to ghcr.io.
    with:
      image: app
      dockerfile: app.Dockerfile # Optional, default is `<image>.Dockerfile`.
      timeout: 5 # Optional, default is `5`.
```

## Dispatch to Ynfra

The `dispatch_to_ynfra.yaml` workflow sends a `repository_dispatch` event to `<owner>/ynfra`.

The `YNFRA_DISPATCH_TOKEN` secret is in the `environment` of the caller repository.
The caller must pass it by name, otherwise it is empty.

```yaml
jobs:
  dispatch:
    name: Workflows
    needs: build
    uses: ystorian/workflows/.github/workflows/dispatch_to_ynfra.yaml@main
    permissions:
      contents: read
    with:
      event: restart-app
      environment: production # Optional, default is `production`.
    secrets:
      YNFRA_DISPATCH_TOKEN: ${{ secrets.YNFRA_DISPATCH_TOKEN }}
```

## Pinning

Pin the workflows to a commit SHA. Update them with `just update_actions`.
