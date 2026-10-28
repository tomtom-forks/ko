# GitHub Action

This repository provides a [Docker container action](https://docs.github.com/en/actions/tutorials/use-containerized-services/create-a-docker-container-action) that runs `ko build` inside the [`ko` container image](https://github.com/ko-build/ko/pkgs/container/ko) published with every release, so no installation step is needed. It requires a Linux runner.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ko-build/ko@v0.19.0
    id: ko
    with:
      importpaths: ./cmd/app
      docker-repo: ghcr.io/${{ github.repository }}
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ github.token }}
      tags: |
        latest
        ${{ github.sha }}
      labels: org.opencontainers.image.source=${{ github.server_url }}/${{ github.repository }}
  - run: jq -r '.images[0].ref' <<<"${JSON}"
    env:
      JSON: ${{ steps.ko.outputs.json }}
```

The action builds `FROM` the `latest` image, which the `image` workflow publishes from `main`. Files it writes, such as `refs` and `sbom-dir`, are owned by root.

The container does not see the runner's Docker config, so a login done by `docker/login-action` does not reach it. Pass `registry`, `username` and `password` instead.

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
| `registry`, `username`, `password` | `ko login` | |

`tags`, `labels`, `annotations` and `platform` accept values separated by commas or newlines. The `KO_*` inputs fall back to the environment variables of the same name. `--local` is not supported, since the container has no access to the Docker daemon.

## Outputs

| Output | Content |
|--------|---------|
| `json` | The whole [JSON document](json-output.md) written by `ko build`. Empty unless `output` is `json`. |
| `tags` | The `tags` of the JSON document, as a JSON array. |
| `digest` | The digest of the first image of the JSON document. |
