# GitHub Action

This repository provides a composite GitHub Action that runs `ko build` using the [`ko` container image](https://github.com/ko-build/ko/pkgs/container/ko) published with every release, so no installation step is needed. It requires a Linux runner with Docker.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ github.token }}
  - uses: ko-build/ko@v0.19.0
    id: ko
    with:
      importpaths: ./cmd/app
      docker-repo: ghcr.io/${{ github.repository }}
      tags: |
        latest
        ${{ github.sha }}
      labels: org.opencontainers.image.source=${{ github.server_url }}/${{ github.repository }}
  - run: jq -r '.images[0].ref' <<<"${JSON}"
    env:
      JSON: ${{ steps.ko.outputs.json }}
```

The image version follows the ref the action is used at: `@v0.19.0` runs `ghcr.io/ko-build/ko:v0.19.0`, any other ref (a branch or a SHA) runs `:latest`. Set `image` to choose another one.

The container reads registry credentials from the runner's Docker config, so log in with `docker/login-action` first. It runs as the runner's user in the workspace, so paths such as `refs` and `sbom-dir` are written where later steps can read them.

## Inputs

| Input | `ko build` flag | Default |
|-------|-----------------|---------|
| `importpaths` | arguments | `.` |
| `working-directory` | | `.` |
| `annotations` | `--image-annotation` | |
| `labels` | `--image-label` | |
| `refs` | `--image-refs` | |
| `user` | `--image-user` | |
| `output` | `--output` | `json` |
| `sbom` | `--sbom` | `spdx` |
| `tags` | `--tags` | `latest` |
| `ldflags` | `--ldflags`, one set per line | |
| `platform` | `--platform` | |
| `push` | `--push` | `true` |
| `bare`, `base-import-paths`, `preserve-import-paths`, `tag-only`, `insecure-registry`, `disable-optimizations` | the flag of the same name | `false` |
| `sbom-dir`, `oci-layout-path`, `tarball`, `jobs` | the flag of the same name | |
| `docker-repo` | `KO_DOCKER_REPO` | |
| `config-path` | `KO_CONFIG_PATH` | |
| `default-base-image` | `KO_DEFAULTBASEIMAGE` | |
| `default-platforms` | `KO_DEFAULTPLATFORMS` | |
| `data-date-epoch` | `KO_DATA_DATE_EPOCH` | |
| `image` | | the `ko` image matching the action's ref |

`tags`, `labels`, `annotations` and `platform` accept values separated by commas or newlines. The `KO_*` inputs fall back to the environment variables of the same name. `--local` is not supported, since the container has no access to the Docker daemon.

## Outputs

| Output | Content |
|--------|---------|
| `json` | The whole [JSON document](json-output.md) written by `ko build`. Empty unless `output` is `json`. |
| `tags` | The `tags` of the JSON document, as a JSON array. |
| `digest` | The digest of the first image of the JSON document. |
