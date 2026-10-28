#!/bin/bash
# Entrypoint of the GitHub Action defined in action.yml. GitHub passes every
# input as an INPUT_<NAME> environment variable.
set -euo pipefail

output="${INPUT_OUTPUT,,}"
args=(build --output "${output}" --push="${INPUT_PUSH,,}" --sbom "${INPUT_SBOM}")

# join collapses newlines into commas, the separator ko's slice flags accept.
join() { tr '\n' ',' <<<"$1" | sed -e 's/,\{2,\}/,/g' -e 's/^,//' -e 's/,$//'; }

flag() { [[ -z "$2" ]] || args+=("$1" "$2"); }
toggle() { [[ "${2,,}" != "true" ]] || args+=("$1"); }

flag --tags "$(join "${INPUT_TAGS}")"
flag --image-annotation "$(join "${INPUT_ANNOTATIONS}")"
flag --image-label "$(join "${INPUT_LABELS}")"
flag --image-refs "${INPUT_REFS}"
flag --image-user "${INPUT_USER}"
flag --platform "$(join "${INPUT_PLATFORM}")"
flag --sbom-dir "${INPUT_SBOM_DIR}"
flag --oci-layout-path "${INPUT_OCI_LAYOUT_PATH}"
flag --tarball "${INPUT_TARBALL}"
flag --jobs "${INPUT_JOBS}"
toggle --bare "${INPUT_BARE}"
toggle --base-import-paths "${INPUT_BASE_IMPORT_PATHS}"
toggle --preserve-import-paths "${INPUT_PRESERVE_IMPORT_PATHS}"
toggle --tag-only "${INPUT_TAG_ONLY}"
toggle --insecure-registry "${INPUT_INSECURE_REGISTRY}"
toggle --disable-optimizations "${INPUT_DISABLE_OPTIMIZATIONS}"

while IFS= read -r line; do
  [[ -z "${line// /}" ]] || args+=(--ldflags "${line}")
done <<<"${INPUT_LDFLAGS}"

# Import paths are separated by whitespace.
read -r -a importpaths <<<"$(tr '\n' ' ' <<<"${INPUT_IMPORTPATHS:-.}")"
args+=("${importpaths[@]}")

# Inputs win over the environment of the workflow.
[[ -z "${INPUT_DOCKER_REPO}" ]] || export KO_DOCKER_REPO="${INPUT_DOCKER_REPO}"
[[ -z "${INPUT_CONFIG_PATH}" ]] || export KO_CONFIG_PATH="${INPUT_CONFIG_PATH}"
[[ -z "${INPUT_DEFAULT_BASE_IMAGE}" ]] || export KO_DEFAULTBASEIMAGE="${INPUT_DEFAULT_BASE_IMAGE}"
[[ -z "${INPUT_DEFAULT_PLATFORMS}" ]] || export KO_DEFAULTPLATFORMS="${INPUT_DEFAULT_PLATFORMS}"
[[ -z "${INPUT_DATA_DATE_EPOCH}" ]] || export KO_DATA_DATE_EPOCH="${INPUT_DATA_DATE_EPOCH}"

# The container does not see the runner's Docker config, so log in here.
if [[ -n "${INPUT_PASSWORD}" ]]; then
  /ko-app/ko login "${INPUT_REGISTRY}" --username "${INPUT_USERNAME}" --password-stdin <<<"${INPUT_PASSWORD}"
fi

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}"

stdout="$(mktemp)"
/ko-app/ko "${args[@]}" >"${stdout}"
cat "${stdout}"

if [[ "${output}" == "json" ]]; then
  delimiter="ko_$(cat /proc/sys/kernel/random/uuid)"
  {
    echo "json<<${delimiter}"
    cat "${stdout}"
    echo "${delimiter}"
    echo "tags=$(jq -c '.tags' "${stdout}")"
    echo "digest=$(jq -r '.images[0].digest // empty' "${stdout}")"
  } >>"${GITHUB_OUTPUT}"
fi
