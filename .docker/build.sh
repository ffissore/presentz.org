#!/usr/bin/env bash

set -xe

cd .docker

docker build --build-arg USERID=$(id -u) -t presentz-org-node .
