# <img src="https://raw.githubusercontent.com/ystorian/workflows/main/workflows.svg" width="48" align="absmiddle" alt="Workflows logo"> Workflows

Reusable GitHub Actions workflows for Ystorian repositories.

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
It fails when a job in `needs` failed or was cancelled.
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

## Pinning

Pin the workflows to a commit SHA. Update them with `just update_actions`.
