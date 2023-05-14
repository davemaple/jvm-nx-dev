#!/bin/bash

ROOT_DIR_REL="$(dirname "$0")/.."
ROOT_DIR="$(realpath "$ROOT_DIR_REL")"
TAG="$(cat "$ROOT_DIR"/.version)"

docker buildx build --progress=plain --platform linux/amd64 -t jvm-nx-dev:latest .
docker run --platform linux/amd64 -it jvm-nx-dev:latest /bin/bash
