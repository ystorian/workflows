# Workflows

Reusable GitHub Actions workflows for Ystorian repositories.

## Detect changes

The `changes.yaml` workflow detects relevant file changes with
[`dorny/paths-filter`](https://github.com/dorny/paths-filter).
It reads the `.github/filters.yaml` file of the calling repository.

- On push: the `run` output is the result of the `filter` input.
- On other events: the `run` output is always `true`.

```yaml
jobs:
  changes:
    uses: ystorian/workflows/.github/workflows/changes.yaml@<sha> # v1.0.0
    permissions:
      contents: read
    with:
      filter: ci # Optional, default is `ci`.

  test:
    needs: changes
    if: needs.changes.outputs.run == 'true'
```

Pin the workflow to a commit SHA. Update it with `pinact run --update`.
