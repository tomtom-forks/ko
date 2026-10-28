# Image of the GitHub Action defined in action.yml: the published ko image
# plus the entrypoint that maps the action inputs to `ko build`.
FROM ghcr.io/tomtom-forks/ko:latest

RUN apt-get update \
    && apt-get install --yes --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
