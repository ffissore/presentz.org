#!/usr/bin/env bash

set -xe

docker run -it --rm \
    -v $(pwd):/app \
    -v ~/.npm:/home/username/.npm \
    -v ~/.npmrc:/home/username/.npmrc \
    --network=host \
    presentz-org-node \
    bash
