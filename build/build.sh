#!/bin/bash

ROOT_DIR_REL="$(dirname "$0")/.."
ROOT_DIR="$(realpath "$ROOT_DIR_REL")"
TAG="$(cat "$ROOT_DIR"/.version)"

#docker buildx build --no-cache --progress=plain --platform linux/amd64 -t jvm-nx-dev:latest .
#docker tag jvm-nx-dev:latest gamindev/jvm-nx-dev:latest
#docker tag jvm-nx-dev:latest gamindev/jvm-nx-dev:v"$TAG"
#docker push gamindev/jvm-nx-dev:latest
#docker push gamindev/jvm-nx-dev:v"$TAG"
git tag -a v"$TAG" -m "$( date '+%F_%H:%M:%S' )] gamindev/jvm-nx-dev:v$TAG"
git push origin v"$TAG"
