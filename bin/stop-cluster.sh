#! /bin/bash

set -e

source $(dirname $0)/docker.host.sh

docker ps | egrep "${DOCKER_IMAGE}" | cut -d" " -f1 | xargs -I{} docker rm -f {} > /dev/null 2>&1

echo "Stopped the cluster and cleared all of the running containers."

