#!/bin/bash
set -e
set -o pipefail

if [[ -z "$PAGES_BRANCH" ]]; then
    PAGES_BRANCH="gh-pages"
fi

if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="."
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "Set the GITHUB_REPOSITORY env variable."
    exit 1
fi

if [[ -z "$BUILD_ONLY" ]]; then
    BUILD_ONLY=false
fi

if [[ -z "$BUILD_THEMES" ]]; then
    BUILD_THEMES=true
fi

if [[ -z "$DEPLOY_PRIVATE_KEY" ]] && [[ "$BUILD_ONLY" == false ]]; then
    echo "Set the DEPLOY_PRIVATE_KEY env variable."
    exit 1
fi

main() {
    echo "Starting deploy..."

    if [[ "$BUILD_THEMES" ]]; then
        echo "Fetching themes"
        git submodule update --init --recursive
    fi

    version=$(zola --version)

    echo "Using $version"

    echo "Building in $BUILD_DIR directory"
    cd $BUILD_DIR

    echo Building with flags: ${BUILD_FLAGS:+"$BUILD_FLAGS"}
    zola build ${BUILD_FLAGS:+$BUILD_FLAGS}

    if ${BUILD_ONLY}; then
        echo "Build complete. Deployment skipped by request"
        exit 0
    else
        remote_repo="git@github.com:${GITHUB_REPOSITORY}.git"
        remote_branch=$PAGES_BRANCH
        echo "Pushing artifacts to ${GITHUB_REPOSITORY}:$remote_branch"

        # setup ssh deployment key
        export SSH_AUTH_SOCK=/tmp/ssh_agent.sock
        ssh-agent -a $SSH_AUTH_SOCK > /dev/null
        ssh-add - <<< "$DEPLOY_PRIVATE_KEY"

        cd public
        git init
        git config user.name "GitHub Actions"
        git config user.email "github-actions-bot@users.noreply.github.com"
        git add .

        git commit -m "Deploy ${GITHUB_REPOSITORY} to ${GITHUB_REPOSITORY}:$remote_branch"
        export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
        git push --force "${remote_repo}" master:${remote_branch}

        echo "Deploy complete"
    fi
}

main "$@"
