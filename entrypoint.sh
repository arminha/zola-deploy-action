#!/bin/bash
set -e
set -o pipefail

if [[ ! -z "$TOKEN" ]]; then
    GITHUB_TOKEN=$TOKEN
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Set the GITHUB_TOKEN env variable."
    exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "Set the GITHUB_REPOSITORY env variable."
    exit 1
fi

main() {
    version=$(zola --version)
    remote_repo="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    remote_branch="master"

    echo "Building site with $version"

    zola build

    echo "Pushing artifacts to ${GITHUB_REPOSITORY}:$remote_branch"

    cd public
    git init
    git config user.name "${GITHUB_ACTOR}"
    git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
    git add .

    git commit -m "Deploy ${GITHUB_REPOSITORY} to ${GITHUB_REPOSITORY}:$remote_branch"
    git push --force $remote_repo master:$remote_branch

    echo "Deploy complete"
}

main "$@"
