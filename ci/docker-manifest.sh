#!/usr/bin/env bash

set -eu

token="$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$TRAVIS_REPO_SLUG:pull" | jq -r '.token')"
allTags="$(curl -Ls "https://index.docker.io/v2/$TRAVIS_REPO_SLUG/tags/list" -H "Authorization: Bearer $token" | jq '.tags')"

set -x

manifestLists=()
versions=("${TRAVIS_TAG}" "latest")
for version in "${versions[@]}"; do
    tags=($(echo "$allTags" | jq -r --arg version "$version" '.[] | select(. | startswith($version))'))
    manifests=()
    for tag in "${tags[@]}"; do
        manifests+=("$TRAVIS_REPO_SLUG:$tag")
    done
    docker manifest create "$TRAVIS_REPO_SLUG:$version" "${manifests[@]}"
    docker manifest inspect "$TRAVIS_REPO_SLUG:$version"
    manifestLists+=("$TRAVIS_REPO_SLUG:$version")
done

for manifestList in "${manifestLists[@]}"; do
    docker manifest push "$manifestList"
done
